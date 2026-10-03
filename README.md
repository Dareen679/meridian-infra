# Meridian Infra

OpenTofu configuration for Meridian Labs' cloud environment. Provisions a VPC,
an S3 bucket, a DynamoDB table, and (against real AWS only — see note below) an
ECR repository. Designed to run locally against
[LocalStack](https://www.localstack.cloud/) with no real AWS account required.

## Project structure

```
.
├── .github/
│   └── workflows/
│       └── infra.yml   # CI/CD: plan on PRs, apply on merge to main
├── backend.tf           # Terraform/OpenTofu settings, provider config, state backend
├── main.tf              # Resource definitions (VPC, S3, DynamoDB, ECR)
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── .gitignore
└── README.md
```

## A note on ECR and LocalStack

ECR is a [LocalStack Pro-only service](https://docs.localstack.cloud/references/coverage/).
Creating `aws_ecr_repository` against a free-tier LocalStack instance fails with:

```
Sorry, the ecr service is not included within your LocalStack license, but is
available in an upgraded license.
```

To keep local development fully apply-able without a paid LocalStack subscription,
the `aws_ecr_repository.app` resource in `main.tf` has `count = var.use_localstack ? 0 : 1`
— it's **skipped automatically when `use_localstack = true`** and created only when
running against real AWS (`use_localstack = false`). A `aws_dynamodb_table` resource
is included instead as the third always-on resource type (alongside the VPC and S3
bucket), so `tofu plan` / `tofu apply` fully exercise three resource types against
LocalStack's free tier. If your LocalStack account has a Pro license with ECR
included, you can remove the `count` condition to create it locally too.

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) >= 1.6
- [Docker](https://docs.docker.com/get-docker/)
- [LocalStack](https://docs.localstack.cloud/getting-started/installation/) (CLI or Docker)

## Running against LocalStack

1. Start LocalStack:

   ```bash
   localstack start -d
   ```

2. Initialize OpenTofu:

   ```bash
   tofu init
   ```

3. Review the plan:

   ```bash
   tofu plan
   ```

4. Apply:

   ```bash
   tofu apply
   ```

By default, `use_localstack = true` and `localstack_endpoint = "http://localhost:4566"`,
so the AWS provider is automatically pointed at your local LocalStack instance with
dummy credentials — no real AWS credentials are needed.

To tear everything down:

```bash
tofu destroy
```

## Running against real AWS

Set `use_localstack = false` (e.g. via `-var="use_localstack=false"` or a `.tfvars`
file) and ensure your environment has valid AWS credentials. You should also replace
the `local` state backend in `backend.tf` with a remote backend (an example S3 +
DynamoDB configuration is included as a comment) before using this against a shared
or production environment.

## Variables

| Name | Description | Default |
|---|---|---|
| `aws_region` | AWS region to deploy into | `us-east-1` |
| `environment` | Environment name (`dev`, `staging`, `prod`) | `dev` |
| `project_name` | Prefix used for resource names | `meridian` |
| `use_localstack` | Point the provider at LocalStack | `true` |
| `localstack_endpoint` | LocalStack gateway URL | `http://localhost:4566` |
| `vpc_cidr_block` | CIDR block for the VPC | `10.0.0.0/16` |
| `ecr_image_tag_mutability` | ECR tag mutability (`MUTABLE`/`IMMUTABLE`) | `MUTABLE` |
| `s3_force_destroy` | Allow destroying a non-empty S3 bucket | `true` |
| `tags` | Extra tags applied to all resources | `{}` |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | ID of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `ecr_repository_name` | Name of the ECR repository (`null` when `use_localstack = true`) |
| `ecr_repository_url` | Repository URL for docker push/pull (`null` when `use_localstack = true`) |
| `s3_bucket_name` | Name of the S3 bucket |
| `s3_bucket_arn` | ARN of the S3 bucket |
| `dynamodb_table_name` | Name of the DynamoDB table |
| `dynamodb_table_arn` | ARN of the DynamoDB table |

## State backend

State is currently stored locally at `state/terraform.tfstate` (via the `local`
backend in `backend.tf`), which is convenient for LocalStack testing and is excluded
from version control via `.gitignore`. A commented-out example `s3` backend is
included in `backend.tf` for migrating to a remote, shared backend later.

## CI/CD and approval flow

`.github/workflows/infra.yml` wires this project into a GitOps flow: infrastructure
changes are proposed via pull request, reviewed as a `tofu plan`, and only applied
once that PR is merged to `main`.

| Trigger | Job | What runs | Changes infrastructure? |
|---|---|---|---|
| Pull request targeting `main` (touching `*.tf` or the workflow file) | `plan` | `tofu init`, `tofu validate`, `tofu plan` | No |
| Push to `main` (i.e. a PR merge) | `apply` | `tofu init`, `tofu apply -auto-approve` | Yes |

**Review/approval flow:**

1. A change to any `.tf` file is made on a branch and opened as a PR against `main`.
2. The `plan` job runs `tofu init` → `tofu validate` → `tofu plan`, and posts the
   plan output as a comment on the PR, so reviewers can see exactly what will
   change before approving.
3. Branch protection on `main` should require at least one approving review (and
   a passing `plan` job) before the PR can be merged — this is the primary human
   approval gate, and it should be configured in the repo's Settings → Branches.
4. Merging the PR pushes to `main`, which triggers the `apply` job. It re-runs
   `tofu init` and then `tofu apply -auto-approve` using the exact code that was
   reviewed.
5. The `apply` job targets the `production` GitHub Environment. Adding required
   reviewers to that environment (Settings → Environments → `production`) gives
   you an optional *second*, manual approval gate that pauses the apply job until
   someone explicitly approves it — useful if you want a human in the loop beyond
   the PR review itself.
6. `concurrency: infra-${{ github.ref }}` ensures plan/apply runs for the same
   ref don't overlap, which protects against two runs racing on the same state.

**Prerequisites before enabling real applies:**

- **Remote state backend.** The `local` backend in `backend.tf` only writes to
  the GitHub Actions runner's disk, which is destroyed at the end of every job —
  state would not persist between runs, and `apply` would try to recreate
  resources that already exist. Switch to the commented-out `s3` backend example
  in `backend.tf` (or another remote backend) before relying on this workflow for
  real AWS applies.
- **AWS credentials.** The workflow authenticates via OIDC
  (`aws-actions/configure-aws-credentials`) and expects an `AWS_ROLE_ARN`
  repository secret pointing at an IAM role trusted for GitHub Actions OIDC,
  scoped to just the permissions this project needs (VPC, S3, DynamoDB, ECR).
- **`use_localstack` is forced to `false`** in CI (`TF_VAR_use_localstack: "false"`
  in the workflow's `env`), so `apply` always targets real AWS, including the
  ECR repository.

## Notes

- `tofu fmt` is not currently enforced in CI; run `tofu fmt` locally before
  committing if you want consistent formatting.

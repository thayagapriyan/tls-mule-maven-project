# OIDC + IAM for CI (Terraform)

Creates the AWS side of GitHub OIDC so the Mule app CI can read the TLS keystore from S3
**without static access keys**:

- a GitHub Actions OIDC provider (`token.actions.githubusercontent.com`)
- an IAM role whose trust policy is scoped to this repo's branches/PRs
- a least-privilege policy: `s3:GetObject` (+ versioned) on `bucket/<prefix>` only

## Usage

```powershell
cd infra\terraform
Copy-Item terraform.tfvars.example terraform.tfvars   # then edit values

terraform init
terraform plan
terraform apply
```

Take the output and store it as a GitHub **secret**:

```powershell
terraform output -raw ci_role_arn      # -> set repo secret AWS_ROLE_ARN
```

## Notes

- **One provider per account.** `token.actions.githubusercontent.com` can exist only once per
  AWS account. If it already exists, set `create_oidc_provider = false` and the module looks it
  up instead of creating a duplicate.
- **Trust boundary = `allowed_subjects`.** Only the listed refs can assume the role. `pull_request`
  covers same-repo PRs; fork PRs do not get OIDC tokens by default.
- **Least privilege.** `s3_key_prefixes` should match exactly what the plugin's `<key>` values
  read (e.g. `mule-app/*`). Don't widen it to `*`.
- The role is referenced by [../../.github/workflows/build-and-test.yml](../../.github/workflows/build-and-test.yml)
  via the `AWS_ROLE_ARN` secret and `aws-actions/configure-aws-credentials`.
- State contains IAM ARNs (not secrets), but use a remote backend (S3 + DynamoDB lock) for team use.

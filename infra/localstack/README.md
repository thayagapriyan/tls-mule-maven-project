# Local test infra (LocalStack, Terraform)

One command stands up everything the **local** plugin test needs — no AWS account, no
manual `docker`/`keytool`/`aws` steps:

- starts a LocalStack (S3) container and waits until healthy
- generates a throwaway JKS keystore with `keytool` (gitignored, never committed)
- creates the S3 bucket and uploads the keystore

> This is the LOCAL fixture. The real-AWS OIDC infra used by CI lives in
> [../terraform](../terraform).

## Prerequisites

- Docker Desktop running
- JDK on PATH (`keytool`)
- Terraform >= 1.5

## Use

```powershell
cd infra\localstack
terraform init
terraform apply           # starts LocalStack + seeds the keystore

terraform output next_steps   # prints the exact build commands to run
```

Then follow the printed `next_steps` to build the Mule app, and confirm the cert was
injected:

```powershell
Test-Path ..\..\target\classes\certificates\keystore.jks   # -> True
```

Tear it all down (stops the container, deletes the local keystore):

```powershell
terraform destroy
```

## Notes

- **Windows/PowerShell.** The provisioners use `keytool`, `docker`, and the LocalStack
  health endpoint via PowerShell. On macOS/Linux, change the `interpreter` in `main.tf`
  to `["bash", "-c"]` and swap the PowerShell snippets for shell equivalents.
- **The plugin's SDK endpoint.** `terraform output sdk_s3_endpoint` returns
  `http://s3.localhost.localstack.cloud:4566` — set it as `AWS_ENDPOINT_URL_S3` so the
  plugin's AWS SDK v2 client resolves bucket addressing to LocalStack. The plugin needs
  no code change.
- **Rotate the keystore:** `terraform apply -replace=null_resource.keystore`.
- Variables (`bucket_name`, `key`, image, passwords) have working defaults — override in a
  `terraform.tfvars` if needed. State and `*.tfvars` are gitignored.

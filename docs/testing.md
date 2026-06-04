# Testing — TLS Demo Mule Application

Two modes: **local** (LocalStack, no AWS account) and **e2e** (CI: Exchange + real S3 via OIDC).

## Local testing (LocalStack, automated infra)

### Step 1 — install the plugin once
```powershell
cd ..\tls-maven-plugin
mvn clean install -Dinvoker.skip=true
```

### Step 2 — provision local infra (Terraform)
```powershell
cd infra\localstack
terraform init
terraform apply            # starts LocalStack, generates keystore, seeds S3
terraform output next_steps # prints the exact build commands
```

### Step 3 — build the app and verify
```powershell
$env:AWS_ACCESS_KEY_ID="test"; $env:AWS_SECRET_ACCESS_KEY="test"
$env:AWS_DEFAULT_REGION="us-east-1"; $env:AWS_ENDPOINT_URL_S3="http://s3.localhost.localstack.cloud:4566"

cd ..\..
mvn clean package `
  -Dtls.injector.groupId=com.priyan.maven `
  -Dtls.injector.plugin.version=1.0.0-SNAPSHOT `
  -Dtls.bucket=mule-tls-bucket -Dtls.key=mule-app/dev/keystore.jks -Dtls.region=us-east-1

Test-Path target\classes\certificates\keystore.jks      # -> True
```

### Step 4 — tear down
```powershell
cd infra\localstack ; terraform destroy
```

### MUnit only
```powershell
mvn test
```

## End-to-end testing (CI)

`.github/workflows/build-and-test.yml` on every push/PR:
1. write `settings.xml` with the Exchange connected app
2. assume the AWS IAM role via **OIDC**
3. `mvn clean package` — plugin (from Exchange) downloads the keystore from **real S3**
4. assert the keystore is in `target/classes` **and** packaged into the artifact jar
5. MUnit runs during the `test` phase

**Required config:** secrets `EXCHANGE_CLIENT_ID`, `EXCHANGE_CLIENT_SECRET`, `AWS_ROLE_ARN`;
vars `ANYPOINT_ORG_ID`, `AWS_REGION`, `TLS_BUCKET`, `TLS_KEY`. See [deploy.md](deploy.md).

## What "working correctly" means

- Build log shows the plugin's `Downloaded s3://.../keystore.jks (N bytes) -> ...` line.
- `target/classes/certificates/keystore.jks` exists and is non-empty.
- `jar tf target/*-mule-application.jar` contains `certificates/keystore.jks`.
- No `.jks` is tracked by Git.

## Related docs

[develop.md](develop.md) · [deploy.md](deploy.md) · [../infra/localstack/README.md](../infra/localstack/README.md)

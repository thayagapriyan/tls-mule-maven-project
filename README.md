# TLS Demo Mule Application

A sample Mule 4 application that exercises the custom
[`aws-tls-injector-maven-plugin`](../tls-maven-plugin) end to end.

## What it proves

1. The custom plugin runs in the `generate-resources` phase and downloads a keystore
   from S3 into `target/classes/certificates/keystore.jks`.
2. The Mule HTTPS listener ([src/main/mule/tls-https-demo.xml](src/main/mule/tls-https-demo.xml))
   consumes that keystore from the classpath via a `<tls:context>`.
3. No `.jks`/`.p12`/`.pem` is ever committed — see [.gitignore](.gitignore).

## Layout

```
tls-mule-maven-project/
├── pom.xml                              # packaging = mule-application; wires the custom plugin
├── mule-artifact.json
├── src/main/mule/tls-https-demo.xml     # HTTPS flow using the downloaded keystore + a plain flow
├── src/main/resources/log4j2.xml
├── src/test/munit/greeting-flow-test.xml# MUnit tests (CI-friendly, no TLS handshake needed)
└── .github/workflows/build-and-test.yml # LocalStack E2E: seed S3 → build → assert
```

## How the plugin is resolved

The custom plugin is consumed as an **Anypoint Exchange** asset, not built locally. Exchange
publishes every asset under `groupId = your org ID`, so the app references it via the
`anypoint.orgId` property (see [pom.xml](pom.xml)). Maven authenticates to the Exchange Maven
repo with a connected app declared as a `<server id="anypoint-exchange-v3">` in `settings.xml`.

## Configuration

| Property          | Meaning                                              |
| ----------------- | ---------------------------------------------------- |
| `anypoint.orgId`  | Anypoint org/business-group GUID (Exchange groupId)  |
| `tls.bucket`      | S3 bucket holding the keystore                       |
| `tls.key`         | S3 object key, e.g. `mule-app/dev/keystore.jks`      |
| `tls.region`      | AWS region                                           |

## Testing locally (real AWS)

```powershell
# 1. Exchange credentials in ~/.m2/settings.xml (server id = anypoint-exchange-v3),
#    using a connected app:  username ~~~Client~~~  password <clientId>~?~<clientSecret>

# 2. AWS creds via SSO/profile — the plugin uses the AWS default credential chain
aws sso login --profile my-profile
$env:AWS_PROFILE = "my-profile"

# 3. Build — the plugin pulls the keystore from the real bucket
mvn clean package `
  -Danypoint.orgId=<your-org-guid> `
  -Dtls.bucket=my-bucket -Dtls.key=mule-app/dev/keystore.jks -Dtls.region=us-east-1

Test-Path target\classes\certificates\keystore.jks      # -> True
```

### MUnit only

```powershell
mvn test
```

## Testing in GitHub Actions

[.github/workflows/build-and-test.yml](.github/workflows/build-and-test.yml) runs on every
push/PR. It resolves the plugin from Exchange, assumes an AWS IAM role via **OIDC** (no static
keys), builds the app so the plugin downloads the keystore from the real bucket, and asserts the
keystore is both written to `target/classes` and packaged into the deployable artifact.

Required repo configuration:

| Kind   | Name                     | Purpose                                          |
| ------ | ------------------------ | ------------------------------------------------ |
| secret | `EXCHANGE_CLIENT_ID`     | Anypoint connected-app client id (Exchange read) |
| secret | `EXCHANGE_CLIENT_SECRET` | connected-app client secret                      |
| secret | `AWS_ROLE_ARN`           | IAM role to assume via OIDC (`s3:GetObject`)     |
| var    | `ANYPOINT_ORG_ID`        | Anypoint org GUID (Exchange groupId)             |
| var    | `AWS_REGION`             | e.g. `us-east-1`                                 |
| var    | `TLS_BUCKET` / `TLS_KEY` | S3 location of the keystore                       |

> The plugin must already be published to Exchange — that is the plugin repo's
> `publish-exchange.yml` workflow (runs on a `v*` tag).

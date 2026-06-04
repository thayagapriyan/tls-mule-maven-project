# Deploy — TLS Demo Mule Application

## Artifact

`mvn clean package` produces `target/tls-demo-app-<version>-mule-application.jar`, a deployable
Mule artifact that **includes** the downloaded `certificates/keystore.jks`.

## Prerequisites for a real build

1. **Plugin published to Exchange** — see the plugin repo's `publish-exchange.yml`
   (`git tag v1.0.0`). The app resolves it under `${anypoint.orgId}`.
2. **AWS OIDC role** — `cd infra/terraform ; terraform apply`; copy `ci_role_arn`.
3. **Keystore in S3** — `aws s3 cp keystore.jks s3://<bucket>/<key>`.
4. **Anypoint connected app** — Exchange Viewer; note client id/secret.

## CI pipeline — `.github/workflows/build-and-test.yml`

Resolves the plugin from Exchange, assumes the IAM role via OIDC, downloads the keystore from
real S3, packages and asserts. Required config:

| Kind | Name | Purpose |
|------|------|---------|
| secret | `EXCHANGE_CLIENT_ID` / `EXCHANGE_CLIENT_SECRET` | Exchange Maven auth |
| secret | `AWS_ROLE_ARN` | IAM role assumed via OIDC |
| var | `ANYPOINT_ORG_ID` | Exchange groupId of the plugin |
| var | `AWS_REGION`, `TLS_BUCKET`, `TLS_KEY` | S3 location |

## Deploying the artifact (out of scope of this demo)

The produced `mule-application.jar` can be deployed to CloudHub 2.0, Runtime Fabric, or a
standalone Mule runtime via the Mule Maven plugin (`mvn deploy -DmuleDeploy ...`) with the
appropriate `<cloudHubDeployment>`/`<standaloneDeployment>` config and Anypoint credentials.
This repo focuses on **build-time cert injection**, not target deployment.

## IAM least privilege

The CI role grants only `s3:GetObject`/`GetObjectVersion` on `bucket/<prefix>` and prefix-scoped
`ListBucket` — see [LLD.md](LLD.md) and `infra/terraform`.

## Related docs

[testing.md](testing.md) · [HLD.md](HLD.md) · [../infra/terraform/README.md](../infra/terraform/README.md)

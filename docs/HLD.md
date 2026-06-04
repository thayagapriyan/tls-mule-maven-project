# High-Level Design — TLS Demo Mule Application

## Context

```
Anypoint Exchange ──(plugin asset)──▶ Mule app build ──▶ deployable mule-application.jar
                                          │
                          OIDC ──▶ IAM role ──▶ AWS S3 (keystore)
```

## Responsibilities

| # | Responsibility | Where |
|---|----------------|-------|
| 1 | Resolve the custom plugin from Exchange | `pom.xml` repositories + groupId property |
| 2 | Authenticate to AWS without static keys | GitHub OIDC + `infra/terraform` IAM role |
| 3 | Trigger the plugin to fetch the keystore | plugin execution bound to `generate-resources` |
| 4 | Consume the keystore over TLS | `<tls:context>` in `tls-https-demo.xml` |
| 5 | Package the cert into the artifact | Mule Maven plugin (`package`) |
| 6 | Unit-test business logic | MUnit `greeting-flow-test.xml` |

## External systems

- **Anypoint Exchange** — source of the plugin (Maven asset).
- **AWS S3** — source of the keystore object.
- **GitHub Actions** — CI: Exchange resolution + OIDC + real S3 + MUnit + assertions.

## Environments

| Env | Plugin source | AWS backend | Infra |
|-----|---------------|-------------|-------|
| CI (main/PR) | Exchange | real S3 via OIDC | `infra/terraform` |
| Local real | Exchange or local `~/.m2` | real S3 (profile) | — |
| Local LocalStack | local `~/.m2` snapshot | LocalStack S3 | `infra/localstack` |

## Quality attributes

- **Security:** no certs in Git; no static AWS keys; least-privilege S3 read.
- **Reproducibility:** Terraform for both real-AWS OIDC and local LocalStack.
- **Fast feedback:** MUnit + build-time assertions that the cert is injected and packaged.

## Related docs

[architecture.md](architecture.md) · [LLD.md](LLD.md) · [testing.md](testing.md) · [deploy.md](deploy.md)

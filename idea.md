# Idea — TLS Demo Mule Application

## Overview

A sample **Mule 4 application** that proves the custom
[`aws-tls-injector-maven-plugin`](../tls-maven-plugin) works end to end in a realistic consumer:

- the plugin is **resolved from Anypoint Exchange** (not built locally),
- at build time it **downloads a keystore from AWS S3** into `target/classes/certificates`,
- a Mule **HTTPS listener consumes that keystore** from the classpath,
- **no `.jks`/`.p12`/`.pem` is ever committed** to Git.

## Problem it demonstrates

Mule apps need TLS material (keystores/truststores) at runtime, but committing them to VCS is a
compliance risk and injecting them via ad-hoc pipeline scripts is fragile. This app shows the
clean alternative: a Maven-lifecycle plugin that fetches certs from S3 during `generate-resources`.

## Solution shape

| Concern | Choice |
|---------|--------|
| Plugin distribution | Anypoint Exchange (Maven asset, groupId = org id) |
| Cert storage | AWS S3, read at build time |
| CI credentials | GitHub OIDC → IAM role (no static keys) |
| Local testing | LocalStack (Terraform-provisioned), no AWS account |
| Runtime use | `<tls:context>` keystore at `certificates/keystore.jks` |

## Scope

- `secure-hello-flow` — HTTPS endpoint secured by the downloaded keystore.
- `greeting-flow` — plain flow, MUnit-tested (no TLS handshake needed in CI).
- `infra/terraform` — real-AWS OIDC role for CI.
- `infra/localstack` — one-command local fixture (LocalStack + bucket + keystore).

## Configuration contract

| Property | Meaning |
|----------|---------|
| `anypoint.orgId` | Anypoint org GUID = Exchange groupId of the plugin |
| `tls.bucket` / `tls.key` / `tls.region` | S3 location of the keystore |

## Related docs

[docs/architecture.md](docs/architecture.md) · [docs/HLD.md](docs/HLD.md) ·
[docs/LLD.md](docs/LLD.md) · [docs/develop.md](docs/develop.md) ·
[docs/testing.md](docs/testing.md) · [docs/deploy.md](docs/deploy.md)

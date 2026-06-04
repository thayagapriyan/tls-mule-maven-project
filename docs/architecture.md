# Architecture — TLS Demo Mule Application

## Purpose

A `mule-application` that consumes the custom `aws-tls-injector-maven-plugin` to inject a
keystore from S3 at build time, then serves HTTPS using it. It is the real-world integration
test for the plugin.

## Build-time vs runtime

```
BUILD TIME (mvn package)                         RUNTIME (Mule)
────────────────────────                         ──────────────
generate-resources:                              secure-hello-flow:
  custom plugin (from Exchange)                    HTTPS listener :8443
    └─ GetObject from S3 ──▶ target/classes/         └─ Demo_TLS_Context
         certificates/keystore.jks                       keystore: certificates/keystore.jks
package:                                                 (loaded from classpath)
  Mule Maven plugin bundles target/classes
  into the deployable .jar
```

## Project structure

```
tls-mule-maven-project/
├── pom.xml                         packaging=mule-application; wires the custom plugin
├── mule-artifact.json              minMuleVersion / Java spec
├── src/main/mule/tls-https-demo.xml  TLS context + HTTPS flow + greeting flow
├── src/main/resources/log4j2.xml
├── src/test/munit/greeting-flow-test.xml
├── infra/terraform/                real-AWS OIDC role (CI)
├── infra/localstack/               LocalStack fixture (local testing)
└── .github/workflows/build-and-test.yml
```

## Plugin integration

The plugin is declared in `pom.xml` under `groupId=${tls.injector.groupId}` (defaults to
`${anypoint.orgId}`) so it resolves from the `anypoint-exchange-v3` repository. S3 coordinates
are properties (`tls.bucket`/`tls.key`/`tls.region`), overridable per environment.

## Credential paths

| Environment | How AWS identity is obtained |
|-------------|------------------------------|
| CI | GitHub OIDC → IAM role (`infra/terraform`) |
| Local (real AWS) | `aws sso login` / profile |
| Local (LocalStack) | dummy creds + `AWS_ENDPOINT_URL_S3` (`infra/localstack`) |

## Related docs

[idea.md](../idea.md) · [HLD.md](HLD.md) · [LLD.md](LLD.md) · [testing.md](testing.md) · [deploy.md](deploy.md)

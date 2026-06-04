# Development Guide — TLS Demo Mule Application

## Prerequisites

- JDK 17 (per `mule-artifact.json`), Maven 3.9+
- The custom plugin available — either published to Exchange, or installed locally
  (`cd ..\tls-maven-plugin ; mvn clean install -Dinvoker.skip=true`)
- For local infra: Docker + Terraform + AWS CLI

## Project layout

See [architecture.md](architecture.md). Key paths: `src/main/mule/`, `src/test/munit/`,
`infra/terraform/`, `infra/localstack/`.

## Build

```powershell
# Against Exchange-published plugin:
mvn clean package -Danypoint.orgId=<org-guid> -Dtls.bucket=<bucket> -Dtls.key=<key> -Dtls.region=<region>

# Against a locally-installed snapshot (local testing):
mvn clean package `
  -Dtls.injector.groupId=com.priyan.maven `
  -Dtls.injector.plugin.version=1.0.0-SNAPSHOT `
  -Dtls.bucket=mule-tls-bucket -Dtls.key=mule-app/dev/keystore.jks -Dtls.region=us-east-1
```

## MUnit

```powershell
mvn test
```

## Conventions

- **Never commit cert material** — `.gitignore` blocks `*.jks/*.p12/*.pem` and `target/`.
- Keep TLS passwords out of source — demo uses `changeit`; real apps use secure properties.
- The keystore path in the flow (`certificates/keystore.jks`) must match the plugin's
  `targetFileName`. Change both together.
- Plugin coordinates are properties — switch Exchange vs local via `-Dtls.injector.*`.

## Adding a downloaded file

1. Add a `<file>` entry to the plugin config in `pom.xml`.
2. Reference it from the relevant Mule config (e.g. a truststore in the `<tls:context>`).
3. Update the LocalStack fixture (`infra/localstack`) if it should be seeded locally.
4. Update [CHANGELOG.md](../CHANGELOG.md) and the affected docs.

## Related docs

[architecture.md](architecture.md) · [LLD.md](LLD.md) · [testing.md](testing.md) · [deploy.md](deploy.md)

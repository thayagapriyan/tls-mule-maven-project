# Low-Level Design — TLS Demo Mule Application

## pom.xml

- `packaging=mule-application`; Mule Maven plugin with `<extensions>true</extensions>`.
- **Custom plugin** declared under `groupId=${tls.injector.groupId}` (= `${anypoint.orgId}`),
  `artifactId=aws-tls-injector-maven-plugin`, `version=${tls.injector.plugin.version}`,
  execution bound to `generate-resources`, config:
  ```xml
  <files><file>
    <bucket>${tls.bucket}</bucket>
    <key>${tls.key}</key>
    <targetFileName>certificates/keystore.jks</targetFileName>
  </file></files>
  ```
- **Repositories:** `mulesoft-public` (anonymous) + `anypoint-exchange-v3`
  (`.../organizations/${anypoint.orgId}/maven`, auth via `settings.xml` server of the same id).
- **Properties:** `anypoint.orgId`, `tls.injector.groupId`, `tls.injector.plugin.version`,
  `tls.bucket`, `tls.key`, `tls.region`, `app.runtime`, `mule.maven.plugin.version`, `munit.version`.

## Mule config — `src/main/mule/tls-https-demo.xml`

- `<tls:context name="Demo_TLS_Context">` → `<tls:key-store type="jks"
  path="certificates/keystore.jks" alias="mule-tls" .../>` (classpath-relative; passwords are
  demo values, use secure properties for real secrets).
- `HTTPS_Listener_config` on `0.0.0.0:8443`, `protocol=HTTPS`, `tlsContext=Demo_TLS_Context`.
- `secure-hello-flow` — listener `/secure-hello` → JSON payload.
- `greeting-flow` — plain transform (`payload.name default 'world'`), MUnit-friendly.

## Tests — `src/test/munit/greeting-flow-test.xml`

Two MUnit tests over `greeting-flow` (named greeting + default), asserting on `payload.greeting`.

## Infrastructure

### `infra/terraform` (real AWS, CI)
- `aws_iam_openid_connect_provider` (toggle), trust policy scoped to
  `repo:<owner>/<repo>:` + `allowed_subjects`, least-privilege S3 read policy
  (`s3:GetObject`/`GetObjectVersion` on `bucket/<prefix>`). Output: `ci_role_arn`.

### `infra/localstack` (local)
- `null_resource.localstack` — docker run + health wait (PowerShell).
- `null_resource.keystore` — `keytool` generates a throwaway JKS.
- `aws_s3_bucket` + `aws_s3_object` (provider pointed at LocalStack, path-style).
- Output `next_steps` prints the env vars + `mvn package` command.

## CI — `.github/workflows/build-and-test.yml`

OIDC (`aws-actions/configure-aws-credentials`) + Exchange `settings.xml` → `mvn clean package`
→ assert `target/classes/certificates/keystore.jks` exists and is in the artifact jar.

## Related docs

[architecture.md](architecture.md) · [HLD.md](HLD.md) · [develop.md](develop.md) · [testing.md](testing.md)

# CLAUDE.md

Guidance for Claude Code (and other AI agents) when working in this repository.

> **Start with [AGENTS.md](AGENTS.md).** It is the documentation index for this repo and links
> the design docs (`idea.md`, `docs/architecture.md`, `docs/HLD.md`, `docs/LLD.md`,
> `docs/develop.md`, `docs/testing.md`, `docs/deploy.md`) and the `infra/*` READMEs. **You must
> follow the doc-maintenance rule in AGENTS.md**: when you change pom config, Mule flows, MUnit,
> workflows, or infra, update the affected docs and append a [CHANGELOG.md](CHANGELOG.md) entry in
> the same change.

## What this project is

A sample **Mule 4 application** (`packaging=mule-application`) that proves the custom
[`aws-tls-injector-maven-plugin`](../tls-maven-plugin) works end to end. It resolves the plugin
from **Anypoint Exchange**, the plugin downloads a keystore from **AWS S3** at build time
(`target/classes/certificates/keystore.jks`), and a Mule HTTPS listener consumes it. See
[idea.md](idea.md) for intent.

## Key conventions (hard rules)

- **Never commit certificate files** (`*.jks`/`*.p12`/`*.pem`) or `target/` — `.gitignore`
  enforces this. Certs come from S3 at build time only.
- **No static AWS keys.** CI uses GitHub OIDC → IAM role (`infra/terraform`); local uses a
  profile or LocalStack (`infra/localstack`).
- **Plugin coordinates are properties.** `groupId=${anypoint.orgId}` (the org GUID) matches how
  the plugin is published *and* installed locally, so local testing only overrides the version:
  `-Dtls.injector.plugin.version=1.0.0-SNAPSHOT`.
- The keystore path in the Mule `<tls:context>` (`certificates/keystore.jks`) must match the
  plugin's `targetFileName` — change them together.
- Keep TLS passwords out of source (demo uses `changeit`; real apps use secure properties).

## Build & test

```powershell
mvn clean package    # plugin downloads keystore -> Mule packages it
mvn test             # MUnit only
```

See [docs/testing.md](docs/testing.md) for the full local (LocalStack) and e2e (CI) flows.

## Environment

Windows + PowerShell — use PowerShell syntax in examples (`$env:VAR`, not `$VAR`).

# AGENTS.md — TLS Demo Mule Application

Entry point for AI agents and contributors. Read this first, then the linked docs.

## What this project is

A sample Mule 4 application that proves the custom `aws-tls-injector-maven-plugin` works end to
end: it resolves the plugin from **Anypoint Exchange**, the plugin downloads a keystore from
**AWS S3** at build time, and a Mule HTTPS listener consumes it. No certs are committed to Git.

## Documentation map

| Doc | Read it for |
|-----|-------------|
| [idea.md](idea.md) | Purpose, problem, solution shape (**start here**) |
| [docs/architecture.md](docs/architecture.md) | Build-time vs runtime, structure, plugin integration |
| [docs/HLD.md](docs/HLD.md) | High-level design: context, responsibilities, environments |
| [docs/LLD.md](docs/LLD.md) | pom.xml, Mule config, MUnit, infra modules |
| [docs/develop.md](docs/develop.md) | Prerequisites, build, conventions |
| [docs/testing.md](docs/testing.md) | Local (LocalStack) + e2e (CI) testing |
| [docs/deploy.md](docs/deploy.md) | Build, CI pipeline, required secrets/vars |
| [CHANGELOG.md](CHANGELOG.md) | Chronological history of changes |
| [CLAUDE.md](CLAUDE.md) | Repo-specific agent instructions |
| [infra/terraform/README.md](infra/terraform/README.md) | Real-AWS OIDC role |
| [infra/localstack/README.md](infra/localstack/README.md) | Local LocalStack fixture |

## Working agreements (must follow)

- **Never commit cert material** (`.gitignore` enforces `*.jks/*.p12/*.pem`, `target/`).
- Keep the keystore path in the Mule flow in sync with the plugin's `targetFileName`.
- Plugin coordinates are properties — Exchange (`${anypoint.orgId}`) vs local (`-Dtls.injector.*`).
- No static AWS keys; CI uses OIDC. Match surrounding style; commit only when asked.

## 📌 Documentation-maintenance rule (REQUIRED)

When you change pom config, Mule flows, MUnit, workflows, or infra, you **must** update docs in
the same change:

1. Update the affected doc(s) above (e.g. a new downloaded `<file>` → `docs/LLD.md` +
   `docs/develop.md`; a workflow change → `docs/testing.md`/`docs/deploy.md`; new infra →
   the relevant `infra/*/README.md` + `docs/LLD.md`).
2. Append an entry to [CHANGELOG.md](CHANGELOG.md) under the current date.
3. If you add a new doc, link it from this map and relevant sibling docs.

A code/infra change without its doc update is incomplete.

## Sibling project

[`tls-maven-plugin`](../tls-maven-plugin/AGENTS.md) — the custom plugin this app consumes.

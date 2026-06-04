# Changelog — TLS Demo Mule Application

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each entry also records the **prompt**
that drove the change, so intent stays alongside code.

Agents: append an entry for every pom/flow/MUnit/workflow/infra/doc change (see
[AGENTS.md](AGENTS.md) doc-maintenance rule).

## [Unreleased]

### Added
- **Sample Mule 4 application** consuming the custom `aws-tls-injector-maven-plugin`:
  `pom.xml` (`packaging=mule-application`, plugin wired into `generate-resources`, Mule Maven
  plugin, MUnit), `mule-artifact.json`, `src/main/mule/tls-https-demo.xml`
  (`<tls:context>` + HTTPS `secure-hello-flow` + plain `greeting-flow`),
  `src/main/resources/log4j2.xml`, `src/test/munit/greeting-flow-test.xml`, `.gitignore`.
- **Anypoint Exchange consumption** — `anypoint-exchange-v3` repository + plugin groupId driven
  by `${anypoint.orgId}` / `${tls.injector.groupId}` properties.
- **CI** — `.github/workflows/build-and-test.yml`: writes Exchange `settings.xml`, assumes an AWS
  IAM role via **OIDC**, builds so the plugin downloads the keystore from **real S3**, and asserts
  the keystore is in `target/classes` and packaged into the artifact.
- **`infra/terraform`** — GitHub OIDC provider + IAM role (repo-scoped trust) + least-privilege
  S3 read policy. Output `ci_role_arn` → `AWS_ROLE_ARN` secret.
- **`infra/localstack`** — one-command local fixture: starts LocalStack, generates a throwaway
  keystore with `keytool`, creates the bucket and uploads the keystore; `next_steps` output prints
  the build commands. `terraform destroy` tears it down.
- **Documentation set** — `idea.md`, `AGENTS.md` (index + doc-maintenance rule), `docs/`
  (`architecture`, `HLD`, `LLD`, `develop`, `testing`, `deploy`), `CLAUDE.md`, and this changelog.

### Changed
- `mule-artifact.json` set to `minMuleVersion 4.9.15`, Java spec `17`.

### Prompts
- *"write a sample code in mule app to test this custom plugin. let me know how can we test custom
  maven plugin using github actions"* → scaffolded the Mule app + initial CI.
- *"revisit two repo codespace completely ... tls-mule-maven-project should download custom plugin
  from exchange and read tls files from aws s3"* → wired Exchange resolution + real-S3 via OIDC.
- *"can we create oidc using terraform?"* → added `infra/terraform` (OIDC + IAM role + S3 policy).
- *"can we have any script like terraform to make necessary infra for local testing"* → added
  `infra/localstack` (LocalStack + keystore + bucket via `terraform apply`).
- *"add different .md file like idea.md, architecture.md, HLD.md, LLD.md, develop.md, testing.md,
  deploy.md ... reference into agents.md then refer agents.md into claude.md ... update
  changelog.md"* → created `idea.md` + `docs/` + `AGENTS.md` + `CLAUDE.md` and this changelog.

---

<!--
Maintenance notes:
- Add new work under [Unreleased] in Added/Changed/Fixed/Removed, plus a Prompts bullet.
- On release, rename [Unreleased] to the version + date and start a fresh [Unreleased] block.
- Keep prompts verbatim (quoted) so intent is traceable.
-->

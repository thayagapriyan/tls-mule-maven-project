# Changelog — TLS Demo Mule Application

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each entry also records the **prompt**
that drove the change, so intent stays alongside code.

Agents: append an entry for every pom/flow/MUnit/workflow/infra/doc change (see
[AGENTS.md](AGENTS.md) doc-maintenance rule).

## [Unreleased]

### Changed
- **Resolve the custom plugin from GitHub Packages instead of Anypoint Exchange.** The plugin moved
  to GitHub Packages (Exchange can't host a consumable build plugin). Replaced the
  `anypoint-exchange-v3` `<repository>`/`<pluginRepository>` with a `github` one
  (`https://maven.pkg.github.com/thayagapriyan/tls-maven-plugin`), dropped the `anypoint.orgId`
  property (kept the org-GUID groupId literal in `tls.injector.groupId` so coordinates are
  unchanged), and bumped `tls.injector.plugin.version` `1.0.0` → `1.0.5`. The build workflow now
  authenticates to GitHub Packages with the built-in `GITHUB_TOKEN` (`packages: read`) instead of
  Anypoint connected-app secrets.

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
- **`anypoint.orgId` default set to the real org GUID** (`3075da4c-6c1a-46d3-984a-191b16b7e34e`),
  matching the plugin's published/installed groupId. Local testing therefore no longer needs a
  `-Dtls.injector.groupId` override (only the SNAPSHOT version differs from the pom default);
  updated `infra/localstack` output, `CLAUDE.md`, `docs/develop.md`, and `docs/testing.md`.

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
- *"update maven plugin pom to use my org id as group id 3075da4c-6c1a-46d3-984a-191b16b7e34e"* →
  set `anypoint.orgId` default to the GUID so the app resolves the plugin under the same
  coordinates it is published/installed under; simplified local-testing commands.

---

<!--
Maintenance notes:
- Add new work under [Unreleased] in Added/Changed/Fixed/Removed, plus a Prompts bullet.
- On release, rename [Unreleased] to the version + date and start a fresh [Unreleased] block.
- Keep prompts verbatim (quoted) so intent is traceable.
-->

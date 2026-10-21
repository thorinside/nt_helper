# Workflow changes

Read `workflows/tag-build.yml` before changing platform routing or prerequisites.
It is the release/distribution path, not a PR validation workflow. Keep signing,
store uploads, release publication, and installer packaging there.

`workflows/ci.yml` validates PRs and branch pushes with read-only permissions:
one analysis/full-suite job, then platform builds, then an always-running
`CI success` aggregate that fails on failed, skipped, or cancelled dependencies.
Keep all five existing platforms, explicit runner OS/architecture labels,
`fail-fast: false`, and no tolerated failures. Generate ignored Dart outputs in
each clean checkout. Build jobs must not rerun the full test suite.
Only the analysis/full-suite job uses GitHub-hosted infrastructure. Keep every
platform build and the aggregate on their existing self-hosted routes; hosted
build minutes are expensive. Do not add hosted build fallbacks.

Validate workflow edits with `actionlint .github/workflows/ci.yml` and
`git diff --check`; inspect the triggered run after pushing. YAML is not branch
protection: report required-check configuration separately (see
`docs/developer-feedback.md`). Keep PR code away from signing credentials and
privileged events such as `pull_request_target`.

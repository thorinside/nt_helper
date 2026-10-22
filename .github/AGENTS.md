# Workflow changes

`workflows/ci.yml` validates PRs, branch pushes, and manual dispatch with
read-only permissions: one analysis/full-suite job on hosted Ubuntu, then an
always-running `CI success` aggregate on the existing self-hosted Linux route.
The aggregate must fail unless the analysis/test job succeeds; failed, skipped,
or cancelled dependencies must never produce a green aggregate. Generate
ignored Dart outputs before analysis and the full default test suite. Use the
Flutter action's SDK/pub download caches with OS, architecture, Flutter version,
and lockfile-aware keys; never cache successful checks or generated build output.
Keep pub get, code generation, analysis, and tests unconditional on cache hits.

Normal CI must not build platform binaries. Binary builds belong exclusively in
`workflows/tag-build.yml`, triggered by version tags or explicit release-workflow
dispatch. Read that workflow before changing release routing or prerequisites.
Preserve its platform jobs, runner labels, signing, store uploads, release
publication, and installer packaging. Do not add hosted build fallbacks.

Validate workflow edits with `actionlint .github/workflows/ci.yml` and
`git diff --check`; inspect trigger and aggregate behavior and the exact-head run
after pushing. YAML is not branch protection: report required-check configuration
separately (see `docs/developer-feedback.md`). Keep PR code away from signing
credentials and privileged events such as `pull_request_target`.

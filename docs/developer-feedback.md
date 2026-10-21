# Developer feedback and CI

## Instructions

The root `AGENTS.md` is authoritative; `test/AGENTS.md` covers local test
selection and `.github/AGENTS.md` covers workflow changes. Root `CLAUDE.md`
remains only a pointer because `.github/workflows/claude.yml` uses the Claude
Code action, which discovers that entry point. Inspection found no other tracked
CLAUDE.md files or unique guidance to migrate. Keep substantive instructions in
AGENTS.md rather than maintaining a second copy.

## Fast local checks

For Dart edits, generate ignored outputs after fresh worktree/dependency setup,
format changed files, run `flutter analyze --no-pub`, and select affected Flutter
test files or folders as shown in `test/AGENTS.md`. Expand selection for shared
code. Preserve regression coverage; reducing assertions or skipping tests is not
a feedback optimization.

For docs/workflow-only changes:

```bash
git diff --check
actionlint .github/workflows/ci.yml
```

Check relative links in changed Markdown. No full local Flutter suite is needed
for each edit or ordinary commit. Releases retain the root AGENTS.md full-suite
requirement. Report selected commands, results, and untested areas honestly.

## Validation versus distribution

`ci.yml` runs on every pull request, all branch pushes (not tag pushes), and
manual dispatch, without path filters. Each run executes analysis and the full
default Flutter suite once. Builds depend on that job; each generates its own
ignored code but does not rerun tests. Matrix fail-fast is disabled so separate
build failures remain visible. Superseded runs are cancelled by ref; the final
`CI success` job requires both test and build results to be exactly successful,
including all matrix entries. A failed, skipped, or cancelled dependency cannot
produce a green aggregate.

Runner mapping comes from `tag-build.yml`, corroborated against the organization
runner API on 2026-10-21:

| Work | Labels | Registered machine |
| --- | --- | --- |
| Analysis, full tests, aggregate, Linux, Android | self-hosted, Linux, X64 | dev |
| Windows | self-hosted, Windows, X64 | dev-Windows |
| macOS, iOS | self-hosted, macOS, ARM64 | MacBookPro |

The jobs share existing single-machine capacity and may queue. Linux native
prerequisite checks, JDK 17 / Android NDK / UVCCamera setup, Windows x64, and
Xcode 27 follow the release configuration. Android CI uses a debug APK to avoid
the required release keystore; macOS and iOS compile without signing. These are
compile checks, not distribution/package verification. No release, store,
notarization, installer, or deployment commands run in CI. The existing seven
signed/distribution jobs in `tag-build.yml` remain unchanged.

PR execution on persistent self-hosted machines requires trusted code review and
the organization's fork-workflow approval/isolation policy. Do not approve
untrusted code onto these hosts merely to obtain green checks. CI uses
`pull_request` (not a privileged target event), read-only repository permission,
no signing secrets, and checkouts without persisted credentials. Those measures
do not sandbox code or protect credentials already present on a host.

## Required administrator action before merge

Inspection on 2026-10-21: the main branch protection endpoint returned
`404 Branch not protected`; repository rulesets and effective main branch rules
were empty. Auto-merge was disabled. No existing required checks were removed or
changed by this work.

After the new check has appeared on a PR, an administrator must configure a main
branch rule / ruleset requiring:

- Pull requests and the GitHub Actions check **CI success**, with the branch
  up to date before merge (or equivalent merge-queue validation added first).
- Enforcement for administrators as well; no bypass or automatic merge.
- Existing review/security policies, if configured elsewhere, preserved.

The aggregate covers analysis, the full suite, and all five platform builds.
Verify a failed dependency blocks merging after enabling protection. Workflow
YAML alone does **not** enforce this, and absence of that rule is a merge blocker.
Do not merge this PR until the latest full CI is green and protection is enabled.

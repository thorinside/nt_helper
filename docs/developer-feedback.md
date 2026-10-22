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
default Flutter suite once on GitHub-hosted Ubuntu. Superseded runs are cancelled
by ref. The always-running `CI success` aggregate requires the analysis/test job
result to be exactly successful; a failed, skipped, or cancelled dependency
cannot produce a green aggregate.

| Validation work | Labels | Registered machine |
| --- | --- | --- |
| Analysis, full tests | ubuntu-24.04 | GitHub-hosted Ubuntu |
| Aggregate | self-hosted, Linux, X64 | dev |

Normal CI does not build binaries. All binary builds remain exclusively in
`tag-build.yml`, triggered by `v*` tag pushes or explicit release-workflow manual
dispatch. Its seven signed/distribution jobs, platform routing, prerequisites,
store uploads, packaging, and release publication are unchanged. PR and ordinary
branch pushes do not trigger that workflow.

CI uses `pull_request` (not a privileged target event), read-only repository
permission, no signing secrets, and checkouts without persisted credentials.
Only the fixed aggregate shell command runs on the self-hosted machine; it does
not check out or execute PR code.

## Download caching

The hosted validation job enables the Flutter action's built-in SDK and pub
package caches. Its default keys include OS, architecture, channel, Flutter
version, and SDK hash; the action additionally appends the `pubspec.lock` hash to
the pub key. There is one cache layer per download type, with no broad fallback
keys or cross-OS reuse. See the [Flutter action cache documentation](https://github.com/subosito/flutter-action#caching).

The prior workflow left these caches disabled. Warm caches avoid repeated SDK
and dependency downloads; no fixed time saving is claimed. `flutter pub get`,
code generation, analysis, and the full suite still run on every change. Project
`.dart_tool`, generated sources, `build/`, and test results are not cached. This
job configures no package registry credentials. Release workflow configuration
is unchanged.

## Required check configuration

Inspection on 2026-10-21: the main branch protection endpoint returned
`404 Branch not protected`; repository rulesets and effective main branch rules
were empty. Auto-merge was disabled. No existing required checks were removed or
changed by this work.

To enforce this validation for merges, an administrator can configure a main
branch rule / ruleset requiring:

- Pull requests and the GitHub Actions check **CI success**, with the branch
  up to date before merge (or equivalent merge-queue validation added first).
- Enforcement for administrators as well; no bypass or automatic merge.
- Existing review/security policies, if configured elsewhere, preserved.

The aggregate covers analysis and the full default test suite. Verify a failed
dependency blocks merging after enabling protection. Workflow YAML alone does
**not** configure or enforce branch protection. Policy changes require separate
owner authorization; this workflow does not apply them.

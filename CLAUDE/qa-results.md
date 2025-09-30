# QA Results

## Review Date: 2025-01-12

## Reviewed By: Quinn (Test Architect)

[... existing review content ...]

## Gate Status

Gate: CONCERNS → qa.qaLocation/gates/{epic}.{story}-{slug}.yml
```

# Key Principles

- Keep it minimal and predictable
- Fixed severity scale (low/medium/high)
- Always write to standard path
- Always update story with gate reference
- Clear, actionable findings
```

## Task: nfr-assess
Source: .bmad-core/tasks/nfr-assess.md
- How to use: "Use task nfr-assess with the appropriate agent" and paste relevant parts as needed.

```md
<!-- Powered by BMAD™ Core -->

# nfr-assess

Quick NFR validation focused on the core four: security, performance, reliability, maintainability.

# Inputs

```yaml
required:
  - story_id: '{epic}.{story}' # e.g., "1.3"
  - story_path: `.bmad-core/core-config.yaml` for the `devStoryLocation`

optional:
  - architecture_refs: `.bmad-core/core-config.yaml` for the `architecture.architectureFile`
  - technical_preferences: `.bmad-core/core-config.yaml` for the `technicalPreferences`
  - acceptance_criteria: From story file
```

# Purpose

Assess non-functional requirements for a story and generate:

1. YAML block for the gate file's `nfr_validation` section
2. Brief markdown assessment saved to `qa.qaLocation/assessments/{epic}.{story}-nfr-{YYYYMMDD}.md`

# Process

## 0. Fail-safe for Missing Inputs

If story_path or story file can't be found:

- Still create assessment file with note: "Source story not found"
- Set all selected NFRs to CONCERNS with notes: "Target unknown / evidence missing"
- Continue with assessment to provide value

## 1. Elicit Scope

**Interactive mode:** Ask which NFRs to assess
**Non-interactive mode:** Default to core four (security, performance, reliability, maintainability)

```text
Which NFRs should I assess? (Enter numbers or press Enter for default)
[1] Security (default)
[2] Performance (default)
[3] Reliability (default)
[4] Maintainability (default)
[5] Usability
[6] Compatibility
[7] Portability
[8] Functional Suitability

> [Enter for 1-4]
```

## 2. Check for Thresholds

Look for NFR requirements in:

- Story acceptance criteria
- `docs/architecture/*.md` files
- `docs/technical-preferences.md`

**Interactive mode:** Ask for missing thresholds
**Non-interactive mode:** Mark as CONCERNS with "Target unknown"

```text
No performance requirements found. What's your target response time?
> 200ms for API calls

No security requirements found. Required auth method?
> JWT with refresh tokens
```

**Unknown targets policy:** If a target is missing and not provided, mark status as CONCERNS with notes: "Target unknown"

## 3. Quick Assessment

For each selected NFR, check:

- Is there evidence it's implemented?
- Can we validate it?
- Are there obvious gaps?

## 4. Generate Outputs

# Output 1: Gate YAML Block

Generate ONLY for NFRs actually assessed (no placeholders):

```yaml
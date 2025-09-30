# Tasks

These are reusable task briefs you can reference directly in Codex.

## Task: validate-next-story
Source: .bmad-core/tasks/validate-next-story.md
- How to use: "Use task validate-next-story with the appropriate agent" and paste relevant parts as needed.

```md
<!-- Powered by BMAD™ Core -->

# Validate Next Story Task

# Purpose

To comprehensively validate a story draft before implementation begins, ensuring it is complete, accurate, and provides sufficient context for successful development. This task identifies issues and gaps that need to be addressed, preventing hallucinations and ensuring implementation readiness.

# SEQUENTIAL Task Execution (Do not proceed until current Task is complete)

## 0. Load Core Configuration and Inputs

- Load `.bmad-core/core-config.yaml`
- If the file does not exist, HALT and inform the user: "core-config.yaml not found. This file is required for story validation."
- Extract key configurations: `devStoryLocation`, `prd.*`, `architecture.*`
- Identify and load the following inputs:
  - **Story file**: The drafted story to validate (provided by user or discovered in `devStoryLocation`)
  - **Parent epic**: The epic containing this story's requirements
  - **Architecture documents**: Based on configuration (sharded or monolithic)
  - **Story template**: `bmad-core/templates/story-tmpl.md` for completeness validation

## 1. Template Completeness Validation

- Load `.bmad-core/templates/story-tmpl.yaml` and extract all section headings from the template
- **Missing sections check**: Compare story sections against template sections to verify all required sections are present
- **Placeholder validation**: Ensure no template placeholders remain unfilled (e.g., `{{EpicNum}}`, `{{role}}`, `_TBD_`)
- **Agent section verification**: Confirm all sections from template exist for future agent use
- **Structure compliance**: Verify story follows template structure and formatting

## 2. File Structure and Source Tree Validation

- **File paths clarity**: Are new/existing files to be created/modified clearly specified?
- **Source tree relevance**: Is relevant project structure included in Dev Notes?
- **Directory structure**: Are new directories/components properly located according to project structure?
- **File creation sequence**: Do tasks specify where files should be created in logical order?
- **Path accuracy**: Are file paths consistent with project structure from architecture docs?

## 3. UI/Frontend Completeness Validation (if applicable)

- **Component specifications**: Are UI components sufficiently detailed for implementation?
- **Styling/design guidance**: Is visual implementation guidance clear?
- **User interaction flows**: Are UX patterns and behaviors specified?
- **Responsive/accessibility**: Are these considerations addressed if required?
- **Integration points**: Are frontend-backend integration points clear?

## 4. Acceptance Criteria Satisfaction Assessment

- **AC coverage**: Will all acceptance criteria be satisfied by the listed tasks?
- **AC testability**: Are acceptance criteria measurable and verifiable?
- **Missing scenarios**: Are edge cases or error conditions covered?
- **Success definition**: Is "done" clearly defined for each AC?
- **Task-AC mapping**: Are tasks properly linked to specific acceptance criteria?

## 5. Validation and Testing Instructions Review

- **Test approach clarity**: Are testing methods clearly specified?
- **Test scenarios**: Are key test cases identified?
- **Validation steps**: Are acceptance criteria validation steps clear?
- **Testing tools/frameworks**: Are required testing tools specified?
- **Test data requirements**: Are test data needs identified?

## 6. Security Considerations Assessment (if applicable)

- **Security requirements**: Are security needs identified and addressed?
- **Authentication/authorization**: Are access controls specified?
- **Data protection**: Are sensitive data handling requirements clear?
- **Vulnerability prevention**: Are common security issues addressed?
- **Compliance requirements**: Are regulatory/compliance needs addressed?

## 7. Tasks/Subtasks Sequence Validation

- **Logical order**: Do tasks follow proper implementation sequence?
- **Dependencies**: Are task dependencies clear and correct?
- **Granularity**: Are tasks appropriately sized and actionable?
- **Completeness**: Do tasks cover all requirements and acceptance criteria?
- **Blocking issues**: Are there any tasks that would block others?

## 8. Anti-Hallucination Verification

- **Source verification**: Every technical claim must be traceable to source documents
- **Architecture alignment**: Dev Notes content matches architecture specifications
- **No invented details**: Flag any technical decisions not supported by source documents
- **Reference accuracy**: Verify all source references are correct and accessible
- **Fact checking**: Cross-reference claims against epic and architecture documents

## 9. Dev Agent Implementation Readiness

- **Self-contained context**: Can the story be implemented without reading external docs?
- **Clear instructions**: Are implementation steps unambiguous?
- **Complete technical context**: Are all required technical details present in Dev Notes?
- **Missing information**: Identify any critical information gaps
- **Actionability**: Are all tasks actionable by a development agent?

## 10. Generate Validation Report

Provide a structured validation report including:

### Template Compliance Issues

- Missing sections from story template
- Unfilled placeholders or template variables
- Structural formatting issues

### Critical Issues (Must Fix - Story Blocked)

- Missing essential information for implementation
- Inaccurate or unverifiable technical claims
- Incomplete acceptance criteria coverage
- Missing required sections

### Should-Fix Issues (Important Quality Improvements)

- Unclear implementation guidance
- Missing security considerations
- Task sequencing problems
- Incomplete testing instructions

### Nice-to-Have Improvements (Optional Enhancements)

- Additional context that would help implementation
- Clarifications that would improve efficiency
- Documentation improvements

### Anti-Hallucination Findings

- Unverifiable technical claims
- Missing source references
- Inconsistencies with architecture documents
- Invented libraries, patterns, or standards

### Final Assessment

- **GO**: Story is ready for implementation
- **NO-GO**: Story requires fixes before implementation
- **Implementation Readiness Score**: 1-10 scale
- **Confidence Level**: High/Medium/Low for successful implementation
```

## Task: trace-requirements
Source: .bmad-core/tasks/trace-requirements.md
- How to use: "Use task trace-requirements with the appropriate agent" and paste relevant parts as needed.

```md
<!-- Powered by BMAD™ Core -->

# trace-requirements

Map story requirements to test cases using Given-When-Then patterns for comprehensive traceability.

# Purpose

Create a requirements traceability matrix that ensures every acceptance criterion has corresponding test coverage. This task helps identify gaps in testing and ensures all requirements are validated.

**IMPORTANT**: Given-When-Then is used here for documenting the mapping between requirements and tests, NOT for writing the actual test code. Tests should follow your project's testing standards (no BDD syntax in test code).

# Prerequisites

- Story file with clear acceptance criteria
- Access to test files or test specifications
- Understanding of the implementation

# Traceability Process

## 1. Extract Requirements

Identify all testable requirements from:

- Acceptance Criteria (primary source)
- User story statement
- Tasks/subtasks with specific behaviors
- Non-functional requirements mentioned
- Edge cases documented

## 2. Map to Test Cases

For each requirement, document which tests validate it. Use Given-When-Then to describe what the test validates (not how it's written):

```yaml
requirement: 'AC1: User can login with valid credentials'
test_mappings:
  - test_file: 'auth/login.test.ts'
    test_case: 'should successfully login with valid email and password'
    # Given-When-Then describes WHAT the test validates, not HOW it's coded
    given: 'A registered user with valid credentials'
    when: 'They submit the login form'
    then: 'They are redirected to dashboard and session is created'
    coverage: full

  - test_file: 'e2e/auth-flow.test.ts'
    test_case: 'complete login flow'
    given: 'User on login page'
    when: 'Entering valid credentials and submitting'
    then: 'Dashboard loads with user data'
    coverage: integration
```

## 3. Coverage Analysis

Evaluate coverage for each requirement:

**Coverage Levels:**

- `full`: Requirement completely tested
- `partial`: Some aspects tested, gaps exist
- `none`: No test coverage found
- `integration`: Covered in integration/e2e tests only
- `unit`: Covered in unit tests only

## 4. Gap Identification

Document any gaps found:

```yaml
coverage_gaps:
  - requirement: 'AC3: Password reset email sent within 60 seconds'
    gap: 'No test for email delivery timing'
    severity: medium
    suggested_test:
      type: integration
      description: 'Test email service SLA compliance'

  - requirement: 'AC5: Support 1000 concurrent users'
    gap: 'No load testing implemented'
    severity: high
    suggested_test:
      type: performance
      description: 'Load test with 1000 concurrent connections'
```

# Outputs

## Output 1: Gate YAML Block

**Generate for pasting into gate file under `trace`:**

```yaml
trace:
  totals:
    requirements: X
    full: Y
    partial: Z
    none: W
  planning_ref: 'qa.qaLocation/assessments/{epic}.{story}-test-design-{YYYYMMDD}.md'
  uncovered:
    - ac: 'AC3'
      reason: 'No test found for password reset timing'
  notes: 'See qa.qaLocation/assessments/{epic}.{story}-trace-{YYYYMMDD}.md'
```

## Output 2: Traceability Report

**Save to:** `qa.qaLocation/assessments/{epic}.{story}-trace-{YYYYMMDD}.md`

Create a traceability report with:

```markdown
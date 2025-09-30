# Story: {epic}.{story} - {title}

## Coverage Summary

- Total Requirements: X
- Fully Covered: Y (Z%)
- Partially Covered: A (B%)
- Not Covered: C (D%)

## Requirement Mappings

### AC1: {Acceptance Criterion 1}

**Coverage: FULL**

Given-When-Then Mappings:

- **Unit Test**: `auth.service.test.ts::validateCredentials`
  - Given: Valid user credentials
  - When: Validation method called
  - Then: Returns true with user object

- **Integration Test**: `auth.integration.test.ts::loginFlow`
  - Given: User with valid account
  - When: Login API called
  - Then: JWT token returned and session created

### AC2: {Acceptance Criterion 2}

**Coverage: PARTIAL**

[Continue for all ACs...]

## Critical Gaps

1. **Performance Requirements**
   - Gap: No load testing for concurrent users
   - Risk: High - Could fail under production load
   - Action: Implement load tests using k6 or similar

2. **Security Requirements**
   - Gap: Rate limiting not tested
   - Risk: Medium - Potential DoS vulnerability
   - Action: Add rate limit tests to integration suite

## Test Design Recommendations

Based on gaps identified, recommend:

1. Additional test scenarios needed
2. Test types to implement (unit/integration/e2e/performance)
3. Test data requirements
4. Mock/stub strategies

## Risk Assessment

- **High Risk**: Requirements with no coverage
- **Medium Risk**: Requirements with only partial coverage
- **Low Risk**: Requirements with full unit + integration coverage
```

# Traceability Best Practices

## Given-When-Then for Mapping (Not Test Code)

Use Given-When-Then to document what each test validates:

**Given**: The initial context the test sets up

- What state/data the test prepares
- User context being simulated
- System preconditions

**When**: The action the test performs

- What the test executes
- API calls or user actions tested
- Events triggered

**Then**: What the test asserts

- Expected outcomes verified
- State changes checked
- Values validated

**Note**: This is for documentation only. Actual test code follows your project's standards (e.g., describe/it blocks, no BDD syntax).

## Coverage Priority

Prioritize coverage based on:

1. Critical business flows
2. Security-related requirements
3. Data integrity requirements
4. User-facing features
5. Performance SLAs

## Test Granularity

Map at appropriate levels:

- Unit tests for business logic
- Integration tests for component interaction
- E2E tests for user journeys
- Performance tests for NFRs

# Quality Indicators

Good traceability shows:

- Every AC has at least one test
- Critical paths have multiple test levels
- Edge cases are explicitly covered
- NFRs have appropriate test types
- Clear Given-When-Then for each test

# Red Flags

Watch for:

- ACs with no test coverage
- Tests that don't map to requirements
- Vague test descriptions
- Missing edge case coverage
- NFRs without specific tests

# Integration with Gates

This traceability feeds into quality gates:

- Critical gaps → FAIL
- Minor gaps → CONCERNS
- Missing P0 tests from test-design → CONCERNS

## Output 3: Story Hook Line

**Print this line for review task to quote:**

```text
Trace matrix: qa.qaLocation/assessments/{epic}.{story}-trace-{YYYYMMDD}.md
```

- Full coverage → PASS contribution

# Key Principles

- Every requirement must be testable
- Use Given-When-Then for clarity
- Identify both presence and absence
- Prioritize based on risk
- Make recommendations actionable
```

## Task: test-design
Source: .bmad-core/tasks/test-design.md
- How to use: "Use task test-design with the appropriate agent" and paste relevant parts as needed.

```md
<!-- Powered by BMAD™ Core -->

# test-design

Create comprehensive test scenarios with appropriate test level recommendations for story implementation.

# Inputs

```yaml
required:
  - story_id: '{epic}.{story}' # e.g., "1.3"
  - story_path: '{devStoryLocation}/{epic}.{story}.*.md' # Path from core-config.yaml
  - story_title: '{title}' # If missing, derive from story file H1
  - story_slug: '{slug}' # If missing, derive from title (lowercase, hyphenated)
```

# Purpose

Design a complete test strategy that identifies what to test, at which level (unit/integration/e2e), and why. This ensures efficient test coverage without redundancy while maintaining appropriate test boundaries.

# Dependencies

```yaml
data:
  - test-levels-framework.md # Unit/Integration/E2E decision criteria
  - test-priorities-matrix.md # P0/P1/P2/P3 classification system
```

# Process

## 1. Analyze Story Requirements

Break down each acceptance criterion into testable scenarios. For each AC:

- Identify the core functionality to test
- Determine data variations needed
- Consider error conditions
- Note edge cases

## 2. Apply Test Level Framework

**Reference:** Load `test-levels-framework.md` for detailed criteria

Quick rules:

- **Unit**: Pure logic, algorithms, calculations
- **Integration**: Component interactions, DB operations
- **E2E**: Critical user journeys, compliance

## 3. Assign Priorities

**Reference:** Load `test-priorities-matrix.md` for classification

Quick priority assignment:

- **P0**: Revenue-critical, security, compliance
- **P1**: Core user journeys, frequently used
- **P2**: Secondary features, admin functions
- **P3**: Nice-to-have, rarely used

## 4. Design Test Scenarios

For each identified test need, create:

```yaml
test_scenario:
  id: '{epic}.{story}-{LEVEL}-{SEQ}'
  requirement: 'AC reference'
  priority: P0|P1|P2|P3
  level: unit|integration|e2e
  description: 'What is being tested'
  justification: 'Why this level was chosen'
  mitigates_risks: ['RISK-001'] # If risk profile exists
```

## 5. Validate Coverage

Ensure:

- Every AC has at least one test
- No duplicate coverage across levels
- Critical paths have multiple levels
- Risk mitigations are addressed

# Outputs

## Output 1: Test Design Document

**Save to:** `qa.qaLocation/assessments/{epic}.{story}-test-design-{YYYYMMDD}.md`

```markdown
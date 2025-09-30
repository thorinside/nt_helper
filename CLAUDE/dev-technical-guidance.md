# Dev Technical Guidance

## Existing System Context

[Extract from available documentation]

## Integration Approach

[Based on patterns found or ask user]

## Technical Constraints

[From documentation or user input]

## Missing Information

Critical: List anything you couldn't find that dev will need and ask for the missing information

## 4. Task Generation with Safety Checks

### 4.1 Generate Implementation Tasks

Based on gathered context, create tasks that:

- Include exploration tasks if system understanding is incomplete
- Add verification tasks for existing functionality
- Include rollback considerations
- Reference specific files/patterns when known

Example task structure for brownfield:

```markdown
# Tasks / Subtasks

- [ ] Task 1: Analyze existing {{component/feature}} implementation
  - [ ] Review {{specific files}} for current patterns
  - [ ] Document integration points
  - [ ] Identify potential impacts

- [ ] Task 2: Implement {{new functionality}}
  - [ ] Follow pattern from {{example file}}
  - [ ] Integrate with {{existing component}}
  - [ ] Maintain compatibility with {{constraint}}

- [ ] Task 3: Verify existing functionality
  - [ ] Test {{existing feature 1}} still works
  - [ ] Verify {{integration point}} behavior unchanged
  - [ ] Check performance impact

- [ ] Task 4: Add tests
  - [ ] Unit tests following {{project test pattern}}
  - [ ] Integration test for {{integration point}}
  - [ ] Update existing tests if needed
```
````

## 5. Risk Assessment and Mitigation

CRITICAL: for brownfield - always include risk assessment

Add section for brownfield-specific risks:

```markdown
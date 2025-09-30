# Risk Assessment

## Implementation Risks

- **Primary Risk**: {{main risk to existing system}}
- **Mitigation**: {{how to address}}
- **Verification**: {{how to confirm safety}}

## Rollback Plan

- {{Simple steps to undo changes if needed}}

## Safety Checks

- [ ] Existing {{feature}} tested before changes
- [ ] Changes can be feature-flagged or isolated
- [ ] Rollback procedure documented
```

## 6. Final Story Validation

Before finalizing:

1. **Completeness Check**:
   - [ ] Story has clear scope and acceptance criteria
   - [ ] Technical context is sufficient for implementation
   - [ ] Integration approach is defined
   - [ ] Risks are identified with mitigation

2. **Safety Check**:
   - [ ] Existing functionality protection included
   - [ ] Rollback plan is feasible
   - [ ] Testing covers both new and existing features

3. **Information Gaps**:
   - [ ] All critical missing information gathered from user
   - [ ] Remaining unknowns documented for dev agent
   - [ ] Exploration tasks added where needed

## 7. Story Output Format

Save the story with appropriate naming:

- If from epic: `docs/stories/epic-{n}-story-{m}.md`
- If standalone: `docs/stories/brownfield-{feature-name}.md`
- If sequential: Follow existing story numbering

Include header noting documentation context:

```markdown
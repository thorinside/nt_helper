# Timeline and Priority

[If applicable, any time constraints or phasing]
```

## 5. Review and Refinement

1. **Present Complete Prompt**
   - Show the full research prompt
   - Explain key elements and rationale
   - Highlight any assumptions made

2. **Gather Feedback**
   - Are the objectives clear and correct?
   - Do the questions address all concerns?
   - Is the scope appropriate?
   - Are output requirements sufficient?

3. **Refine as Needed**
   - Incorporate user feedback
   - Adjust scope or focus
   - Add missing elements
   - Clarify ambiguities

## 6. Next Steps Guidance

**Execution Options:**

1. **Use with AI Research Assistant**: Provide this prompt to an AI model with research capabilities
2. **Guide Human Research**: Use as a framework for manual research efforts
3. **Hybrid Approach**: Combine AI and human research using this structure

**Integration Points:**

- How findings will feed into next phases
- Which team members should review results
- How to validate findings
- When to revisit or expand research

# Important Notes

- The quality of the research prompt directly impacts the quality of insights gathered
- Be specific rather than general in research questions
- Consider both current state and future implications
- Balance comprehensiveness with focus
- Document assumptions and limitations clearly
- Plan for iterative refinement based on initial findings
```

## Task: create-brownfield-story
Source: .bmad-core/tasks/create-brownfield-story.md
- How to use: "Use task create-brownfield-story with the appropriate agent" and paste relevant parts as needed.

```md
<!-- Powered by BMAD™ Core -->

# Create Brownfield Story Task

# Purpose

Create detailed, implementation-ready stories for brownfield projects where traditional sharded PRD/architecture documents may not exist. This task bridges the gap between various documentation formats (document-project output, brownfield PRDs, epics, or user documentation) and executable stories for the Dev agent.

# When to Use This Task

**Use this task when:**

- Working on brownfield projects with non-standard documentation
- Stories need to be created from document-project output
- Working from brownfield epics without full PRD/architecture
- Existing project documentation doesn't follow BMad v4+ structure
- Need to gather additional context from user during story creation

**Use create-next-story when:**

- Working with properly sharded PRD and v4 architecture documents
- Following standard greenfield or well-documented brownfield workflow
- All technical context is available in structured format

# Task Execution Instructions

## 0. Documentation Context

Check for available documentation in this order:

1. **Sharded PRD/Architecture** (docs/prd/, docs/architecture/)
   - If found, recommend using create-next-story task instead

2. **Brownfield Architecture Document** (docs/brownfield-architecture.md or similar)
   - Created by document-project task
   - Contains actual system state, technical debt, workarounds

3. **Brownfield PRD** (docs/prd.md)
   - May contain embedded technical details

4. **Epic Files** (docs/epics/ or similar)
   - Created by brownfield-create-epic task

5. **User-Provided Documentation**
   - Ask user to specify location and format

## 1. Story Identification and Context Gathering

### 1.1 Identify Story Source

Based on available documentation:

- **From Brownfield PRD**: Extract stories from epic sections
- **From Epic Files**: Read epic definition and story list
- **From User Direction**: Ask user which specific enhancement to implement
- **No Clear Source**: Work with user to define the story scope

### 1.2 Gather Essential Context

CRITICAL: For brownfield stories, you MUST gather enough context for safe implementation. Be prepared to ask the user for missing information.

**Required Information Checklist:**

- [ ] What existing functionality might be affected?
- [ ] What are the integration points with current code?
- [ ] What patterns should be followed (with examples)?
- [ ] What technical constraints exist?
- [ ] Are there any "gotchas" or workarounds to know about?

If any required information is missing, list the missing information and ask the user to provide it.

## 2. Extract Technical Context from Available Sources

### 2.1 From Document-Project Output

If using brownfield-architecture.md from document-project:

- **Technical Debt Section**: Note any workarounds affecting this story
- **Key Files Section**: Identify files that will need modification
- **Integration Points**: Find existing integration patterns
- **Known Issues**: Check if story touches problematic areas
- **Actual Tech Stack**: Verify versions and constraints

### 2.2 From Brownfield PRD

If using brownfield PRD:

- **Technical Constraints Section**: Extract all relevant constraints
- **Integration Requirements**: Note compatibility requirements
- **Code Organization**: Follow specified patterns
- **Risk Assessment**: Understand potential impacts

### 2.3 From User Documentation

Ask the user to help identify:

- Relevant technical specifications
- Existing code examples to follow
- Integration requirements
- Testing approaches used in the project

## 3. Story Creation with Progressive Detail Gathering

### 3.1 Create Initial Story Structure

Start with the story template, filling in what's known:

```markdown
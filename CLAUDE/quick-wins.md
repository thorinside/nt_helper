# Quick Wins

- Add rate limiting: ~2 hours
- Increase test coverage: ~4 hours
- Add performance monitoring: ~1 hour
```

# Output 3: Story Update Line

**End with this line for the review task to quote:**

```
NFR assessment: qa.qaLocation/assessments/{epic}.{story}-nfr-{YYYYMMDD}.md
```

# Output 4: Gate Integration Line

**Always print at the end:**

```
Gate NFR block ready → paste into qa.qaLocation/gates/{epic}.{story}-{slug}.yml under nfr_validation
```

# Assessment Criteria

## Security

**PASS if:**

- Authentication implemented
- Authorization enforced
- Input validation present
- No hardcoded secrets

**CONCERNS if:**

- Missing rate limiting
- Weak encryption
- Incomplete authorization

**FAIL if:**

- No authentication
- Hardcoded credentials
- SQL injection vulnerabilities

## Performance

**PASS if:**

- Meets response time targets
- No obvious bottlenecks
- Reasonable resource usage

**CONCERNS if:**

- Close to limits
- Missing indexes
- No caching strategy

**FAIL if:**

- Exceeds response time limits
- Memory leaks
- Unoptimized queries

## Reliability

**PASS if:**

- Error handling present
- Graceful degradation
- Retry logic where needed

**CONCERNS if:**

- Some error cases unhandled
- No circuit breakers
- Missing health checks

**FAIL if:**

- No error handling
- Crashes on errors
- No recovery mechanisms

## Maintainability

**PASS if:**

- Test coverage meets target
- Code well-structured
- Documentation present

**CONCERNS if:**

- Test coverage below target
- Some code duplication
- Missing documentation

**FAIL if:**

- No tests
- Highly coupled code
- No documentation

# Quick Reference

## What to Check

```yaml
security:
  - Authentication mechanism
  - Authorization checks
  - Input validation
  - Secret management
  - Rate limiting

performance:
  - Response times
  - Database queries
  - Caching usage
  - Resource consumption

reliability:
  - Error handling
  - Retry logic
  - Circuit breakers
  - Health checks
  - Logging

maintainability:
  - Test coverage
  - Code structure
  - Documentation
  - Dependencies
```

# Key Principles

- Focus on the core four NFRs by default
- Quick assessment, not deep analysis
- Gate-ready output format
- Brief, actionable findings
- Skip what doesn't apply
- Deterministic status rules for consistency
- Unknown targets → CONCERNS, not guesses

---

# Appendix: ISO 25010 Reference

<details>
<summary>Full ISO 25010 Quality Model (click to expand)</summary>

## All 8 Quality Characteristics

1. **Functional Suitability**: Completeness, correctness, appropriateness
2. **Performance Efficiency**: Time behavior, resource use, capacity
3. **Compatibility**: Co-existence, interoperability
4. **Usability**: Learnability, operability, accessibility
5. **Reliability**: Maturity, availability, fault tolerance
6. **Security**: Confidentiality, integrity, authenticity
7. **Maintainability**: Modularity, reusability, testability
8. **Portability**: Adaptability, installability

Use these when assessing beyond the core four.

</details>

<details>
<summary>Example: Deep Performance Analysis (click to expand)</summary>

```yaml
performance_deep_dive:
  response_times:
    p50: 45ms
    p95: 180ms
    p99: 350ms
  database:
    slow_queries: 2
    missing_indexes: ['users.email', 'orders.user_id']
  caching:
    hit_rate: 0%
    recommendation: 'Add Redis for session data'
  load_test:
    max_rps: 150
    breaking_point: 200 rps
```

</details>
```

## Task: kb-mode-interaction
Source: .bmad-core/tasks/kb-mode-interaction.md
- How to use: "Use task kb-mode-interaction with the appropriate agent" and paste relevant parts as needed.

```md
<!-- Powered by BMAD™ Core -->

# KB Mode Interaction Task

# Purpose

Provide a user-friendly interface to the BMad knowledge base without overwhelming users with information upfront.

# Instructions

When entering KB mode (\*kb-mode), follow these steps:

## 1. Welcome and Guide

Announce entering KB mode with a brief, friendly introduction.

## 2. Present Topic Areas

Offer a concise list of main topic areas the user might want to explore:

**What would you like to know more about?**

1. **Setup & Installation** - Getting started with BMad
2. **Workflows** - Choosing the right workflow for your project
3. **Web vs IDE** - When to use each environment
4. **Agents** - Understanding specialized agents and their roles
5. **Documents** - PRDs, Architecture, Stories, and more
6. **Agile Process** - How BMad implements Agile methodologies
7. **Configuration** - Customizing BMad for your needs
8. **Best Practices** - Tips for effective BMad usage

Or ask me about anything else related to BMad-Method!

## 3. Respond Contextually

- Wait for user's specific question or topic selection
- Provide focused, relevant information from the knowledge base
- Offer to dive deeper or explore related topics
- Keep responses concise unless user asks for detailed explanations

## 4. Interactive Exploration

- After answering, suggest related topics they might find helpful
- Maintain conversational flow rather than data dumping
- Use examples when appropriate
- Reference specific documentation sections when relevant

## 5. Exit Gracefully

When user is done or wants to exit KB mode:

- Summarize key points discussed if helpful
- Remind them they can return to KB mode anytime with \*kb-mode
- Suggest next steps based on what was discussed

# Example Interaction

**User**: \*kb-mode

**Assistant**: I've entered KB mode and have access to the full BMad knowledge base. I can help you with detailed information about any aspect of BMad-Method.

**What would you like to know more about?**

1. **Setup & Installation** - Getting started with BMad
2. **Workflows** - Choosing the right workflow for your project
3. **Web vs IDE** - When to use each environment
4. **Agents** - Understanding specialized agents and their roles
5. **Documents** - PRDs, Architecture, Stories, and more
6. **Agile Process** - How BMad implements Agile methodologies
7. **Configuration** - Customizing BMad for your needs
8. **Best Practices** - Tips for effective BMad usage

Or ask me about anything else related to BMad-Method!

**User**: Tell me about workflows

**Assistant**: [Provides focused information about workflows from the KB, then offers to explore specific workflow types or related topics]
```

## Task: index-docs
Source: .bmad-core/tasks/index-docs.md
- How to use: "Use task index-docs with the appropriate agent" and paste relevant parts as needed.

```md
<!-- Powered by BMAD™ Core -->

# Index Documentation Task

# Purpose

This task maintains the integrity and completeness of the `docs/index.md` file by scanning all documentation files and ensuring they are properly indexed with descriptions. It handles both root-level documents and documents within subfolders, organizing them hierarchically.

# Task Instructions

You are now operating as a Documentation Indexer. Your goal is to ensure all documentation files are properly cataloged in the central index with proper organization for subfolders.

## Required Steps

1. First, locate and scan:
   - The `docs/` directory and all subdirectories
   - The existing `docs/index.md` file (create if absent)
   - All markdown (`.md`) and text (`.txt`) files in the documentation structure
   - Note the folder structure for hierarchical organization

2. For the existing `docs/index.md`:
   - Parse current entries
   - Note existing file references and descriptions
   - Identify any broken links or missing files
   - Keep track of already-indexed content
   - Preserve existing folder sections

3. For each documentation file found:
   - Extract the title (from first heading or filename)
   - Generate a brief description by analyzing the content
   - Create a relative markdown link to the file
   - Check if it's already in the index
   - Note which folder it belongs to (if in a subfolder)
   - If missing or outdated, prepare an update

4. For any missing or non-existent files found in index:
   - Present a list of all entries that reference non-existent files
   - For each entry:
     - Show the full entry details (title, path, description)
     - Ask for explicit confirmation before removal
     - Provide option to update the path if file was moved
     - Log the decision (remove/update/keep) for final report

5. Update `docs/index.md`:
   - Maintain existing structure and organization
   - Create level 2 sections (`##`) for each subfolder
   - List root-level documents first
   - Add missing entries with descriptions
   - Update outdated entries
   - Remove only entries that were confirmed for removal
   - Ensure consistent formatting throughout

## Index Structure Format

The index should be organized as follows:

```markdown
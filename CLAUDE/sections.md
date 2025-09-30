# Sections

- [Section Name 1](./section-name-1.md)
- [Section Name 2](./section-name-2.md)
- [Section Name 3](./section-name-3.md)
  ...
```

## 5. Preserve Special Content

1. **Code blocks**: Must capture complete blocks including:

   ```language
   content
   ```

2. **Mermaid diagrams**: Preserve complete syntax:

   ```mermaid
   graph TD
   ...
   ```

3. **Tables**: Maintain proper markdown table formatting

4. **Lists**: Preserve indentation and nesting

5. **Inline code**: Preserve backticks

6. **Links and references**: Keep all markdown links intact

7. **Template markup**: If documents contain {{placeholders}} ,preserve exactly

## 6. Validation

After sharding:

1. Verify all sections were extracted
2. Check that no content was lost
3. Ensure heading levels were properly adjusted
4. Confirm all files were created successfully

## 7. Report Results

Provide a summary:

```text
Document sharded successfully:
- Source: [original document path]
- Destination: docs/[folder-name]/
- Files created: [count]
- Sections:
  - section-name-1.md: "Section Title 1"
  - section-name-2.md: "Section Title 2"
  ...
```

# Important Notes

- Never modify the actual content, only adjust heading levels
- Preserve ALL formatting, including whitespace where significant
- Handle edge cases like sections with code blocks containing ## symbols
- Ensure the sharding is reversible (could reconstruct the original from shards)
```

## Task: risk-profile
Source: .bmad-core/tasks/risk-profile.md
- How to use: "Use task risk-profile with the appropriate agent" and paste relevant parts as needed.

```md
<!-- Powered by BMAD™ Core -->

# risk-profile

Generate a comprehensive risk assessment matrix for a story implementation using probability × impact analysis.

# Inputs

```yaml
required:
  - story_id: '{epic}.{story}' # e.g., "1.3"
  - story_path: 'docs/stories/{epic}.{story}.*.md'
  - story_title: '{title}' # If missing, derive from story file H1
  - story_slug: '{slug}' # If missing, derive from title (lowercase, hyphenated)
```

# Purpose

Identify, assess, and prioritize risks in the story implementation. Provide risk mitigation strategies and testing focus areas based on risk levels.

# Risk Assessment Framework

## Risk Categories

**Category Prefixes:**

- `TECH`: Technical Risks
- `SEC`: Security Risks
- `PERF`: Performance Risks
- `DATA`: Data Risks
- `BUS`: Business Risks
- `OPS`: Operational Risks

1. **Technical Risks (TECH)**
   - Architecture complexity
   - Integration challenges
   - Technical debt
   - Scalability concerns
   - System dependencies

2. **Security Risks (SEC)**
   - Authentication/authorization flaws
   - Data exposure vulnerabilities
   - Injection attacks
   - Session management issues
   - Cryptographic weaknesses

3. **Performance Risks (PERF)**
   - Response time degradation
   - Throughput bottlenecks
   - Resource exhaustion
   - Database query optimization
   - Caching failures

4. **Data Risks (DATA)**
   - Data loss potential
   - Data corruption
   - Privacy violations
   - Compliance issues
   - Backup/recovery gaps

5. **Business Risks (BUS)**
   - Feature doesn't meet user needs
   - Revenue impact
   - Reputation damage
   - Regulatory non-compliance
   - Market timing

6. **Operational Risks (OPS)**
   - Deployment failures
   - Monitoring gaps
   - Incident response readiness
   - Documentation inadequacy
   - Knowledge transfer issues

# Risk Analysis Process

## 1. Risk Identification

For each category, identify specific risks:

```yaml
risk:
  id: 'SEC-001' # Use prefixes: SEC, PERF, DATA, BUS, OPS, TECH
  category: security
  title: 'Insufficient input validation on user forms'
  description: 'Form inputs not properly sanitized could lead to XSS attacks'
  affected_components:
    - 'UserRegistrationForm'
    - 'ProfileUpdateForm'
  detection_method: 'Code review revealed missing validation'
```

## 2. Risk Assessment

Evaluate each risk using probability × impact:

**Probability Levels:**

- `High (3)`: Likely to occur (>70% chance)
- `Medium (2)`: Possible occurrence (30-70% chance)
- `Low (1)`: Unlikely to occur (<30% chance)

**Impact Levels:**

- `High (3)`: Severe consequences (data breach, system down, major financial loss)
- `Medium (2)`: Moderate consequences (degraded performance, minor data issues)
- `Low (1)`: Minor consequences (cosmetic issues, slight inconvenience)

## Risk Score = Probability × Impact

- 9: Critical Risk (Red)
- 6: High Risk (Orange)
- 4: Medium Risk (Yellow)
- 2-3: Low Risk (Green)
- 1: Minimal Risk (Blue)

## 3. Risk Prioritization

Create risk matrix:

```markdown
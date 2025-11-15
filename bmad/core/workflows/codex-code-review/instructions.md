# Codex Code Review - Instructions

<critical>The workflow execution engine is governed by: {project-root}/bmad/core/tasks/workflow.xml</critical>
<critical>This workflow orchestrates a code review using Codex with developer agent persona</critical>

<workflow>

<step n="1" goal="Prepare Review Context">
  <action>Verify the story file exists at {{story_file}}</action>
  <action>Load the story file to understand acceptance criteria and scope</action>
  <action>Identify related code files, tests, and documentation</action>
</step>

<step n="2" goal="Execute Codex Review">
  <action>Execute the following codex command:</action>
  <format>
    codex e "You are assuming the Developer Agent persona from the BMAD framework.

    Your task is to perform a thorough code review of the completed story at: {{story_file}}

    Review Requirements:
    1. Verify all acceptance criteria are met
    2. Check code quality, patterns, and adherence to project standards
    3. Verify tests are present and passing
    4. Check for any security or performance issues
    5. Ensure documentation is updated appropriately

    After your review, update any relevant BMAD documentation in the docs/ folder if needed to reflect:
    - New patterns discovered
    - Architecture changes
    - Important implementation decisions

    Finally, provide a VERY SHORT summary (2-3 sentences max) with one of these verdicts:
    - '✅ PASS: [brief reason]'
    - '⚠️ CHANGES REQUIRED: [brief list of issues]'

    Story file: {{story_file}}"
  </format>
  <action>Wait for codex to complete the review</action>
  <action>Capture the review output</action>
</step>

<step n="3" goal="Present Review Results">
  <action>Display the codex review results to the user</action>
  <format>
    ━━━━━━━━━━━━━━━━━━━━━━━
    Code Review Complete
    ━━━━━━━━━━━━━━━━━━━━━━━

    [Display codex output]

  </format>
  <action>Confirm workflow completion</action>
</step>

</workflow>

## Review Quality Guidelines

<guidelines>
  <guideline>Codex should assume full developer agent persona from BMAD framework</guideline>
  <guideline>Review must be thorough but concise in final summary</guideline>
  <guideline>All acceptance criteria must be explicitly verified</guideline>
  <guideline>Documentation updates are mandatory, not optional</guideline>
  <guideline>Security and performance issues are critical findings</guideline>
  <guideline>Test coverage must be validated</guideline>
</guidelines>

## Expected Outputs

<outputs>
  <output type="pass">
    ✅ PASS: All acceptance criteria met, tests passing, code quality excellent, docs updated.
  </output>
  <output type="changes">
    ⚠️ CHANGES REQUIRED:
    - Missing test coverage for error cases
    - Security vulnerability in input validation
    - Documentation needs updating for new API
  </output>
</outputs>

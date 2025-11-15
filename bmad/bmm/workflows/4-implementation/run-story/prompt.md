# Run Story - Workflow Instructions

```xml
<critical>The workflow execution engine is governed by: {project-root}/bmad/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {installed_path}/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>Generate all documents in {document_output_language}</critical>
<critical>Execute ALL steps in exact order; do NOT skip steps</critical>
<critical>User skill level ({user_skill_level}) affects conversation style ONLY, not workflow execution.</critical>

<workflow>

  <step n="1" goal="Validate parameters and initialize">
    <!-- Check if story_id is provided first -->
    <check if="{{story_id}} is not empty">
      <output>📋 Parsing story_id: {{story_id}}</output>

      <action>Parse story_id to extract epic and story numbers:
        - Pattern 1: "e5-2" or "e5-2-story-name" → epic=5, story=2
        - Pattern 2: "5-2" or "5-2-story-name" → epic=5, story=2
        - Extract first number after 'e' or at start as epic_number
        - Extract second number after first dash as story_number
      </action>

      <check if="parsing fails or invalid format">
        <output>❌ ERROR: Invalid story_id format

Provided: {{story_id}}
Expected formats: "5-2", "e5-2", "5-2-story-name", or "e5-2-story-name"

Please provide a valid story_id or leave empty to be prompted.
        </output>
        <action>HALT</action>
      </check>

      <action>Override epic_number = {{parsed_epic}}</action>
      <action>Override story_number = {{parsed_story}}</action>
      <output>✅ Extracted Epic {{epic_number}}, Story {{story_number}}</output>
    </check>

    <!-- If no story_id and no epic_number, prompt user -->
    <check if="{{story_id}} is empty AND {{epic_number}} is empty">
      <output>📋 No story specified - loading available stories...</output>

      <action>Load {{sprint_status_file}}</action>
      <action>Parse development_status section</action>
      <action>Extract all story entries (not epic entries, not retrospective entries)</action>
      <action>Filter to stories NOT in "done" status</action>
      <action>Group stories by epic number</action>

      <check if="no pending stories found">
        <output>ℹ️ No pending stories found

All stories in sprint-status.yaml are marked as "done".

Options:
1. Create a new story with /bmad:bmm:workflows:create-story
2. Provide story_id or epic_number/story_number parameters explicitly
        </output>
        <action>HALT</action>
      </check>

      <output>📋 Available Stories (not done):

{{for each epic with pending stories}}
**Epic {{epic_number}}:**
{{for each pending_story in epic}}
  {{story_index}}. {{story_key}} ({{story_status}})
{{end}}
{{end}}

Please select a story by number, or provide story_id/epic_number parameter.
      </output>

      <action>WAIT for user input</action>
      <action>User selects story by number OR provides story_id</action>
      <action>Parse user input to determine selected story</action>
      <action>Extract epic_number and story_number from selected story</action>

      <output>✅ Selected: {{selected_story_key}} (Epic {{epic_number}}, Story {{story_number}})</output>
    </check>

    <!-- If epic_number provided but no story_number, we'll let create-story auto-increment -->
    <check if="{{epic_number}} is not empty AND {{story_number}} is empty">
      <output>📋 Epic {{epic_number}} specified, story_number will be auto-assigned</output>
    </check>

    <!-- Now we should have epic_number at minimum -->
    <check if="{{epic_number}} is still empty">
      <output>❌ ERROR: Cannot determine epic number

Please provide one of:
- story_id parameter (e.g., "5-2" or "e5-2-story-name")
- epic_number parameter (e.g., "5")
- Run without parameters to select from available stories
      </output>
      <action>HALT</action>
    </check>

    <action>Store epic_number and story_number for reference</action>
    <action>Initialize iteration counter: current_iteration = 0</action>
    <action>Initialize review_pass_count = 0</action>

    <output>🚀 Run Story - Complete Story Lifecycle Automation Started

Configuration:
- Epic: {{epic_number}}
- Story Number: {{story_number}} {{if story_number is empty}}(auto-increment){{end}}
- Max Iterations: {{max_iterations}}
- Dev Model: {{dev_model}}
- Review Model: {{review_model}}

Phase 1: Story Drafting...
    </output>
  </step>

  <step n="2" goal="Draft story from epic/tech-spec" tag="draft-story">
    <output>📝 Creating story via SM agent...</output>

    <action>Launch Task sub-agent with:
      - subagent_type: "general-purpose"
      - model: {{review_model}}
      - description: "Draft story for Epic {{epic_number}}"
      - prompt: "Execute the following slash command to create the next story for Epic {{epic_number}}: /bmad:bmm:workflows:create-story

Pass parameters:
- epic_num: {{epic_number}}
- story_num: {{story_number}} (if provided)

Complete all steps in the create-story workflow and capture the generated story file path."
    </action>

    <action>Wait for sub-agent completion</action>
    <action>Extract story_file path from sub-agent output</action>
    <action>Extract story_key from story_file name (e.g., "1-2-user-authentication" from "1-2-user-authentication.md")</action>
    <action>Store story_file and story_key for later use</action>

    <check if="sub-agent reports error or story_file not found">
      <output>❌ HALT: Story creation failed

Please review the error and resolve manually before re-running run-story.
      </output>
      <action>HALT</action>
    </check>

    <output>✅ Story drafted: {{story_file}}

Phase 2: Story Contexting...
    </output>
  </step>

  <step n="3" goal="Create story context XML" tag="context-story">
    <output>🔍 Creating story context via story-context workflow...</output>

    <action>Launch Task sub-agent with:
      - subagent_type: "general-purpose"
      - model: {{review_model}}
      - description: "Create story context for {{story_key}}"
      - prompt: "Execute the following slash command to create context for story {{story_key}}: /bmad:bmm:workflows:story-context

Pass parameters:
- story_path: {{story_file}}

If the workflow asks whether to replace an existing context file, automatically choose 'replace' without prompting.

Complete all steps in the story-context workflow."
    </action>

    <action>Wait for sub-agent completion</action>
    <action>Verify context file created: {{story_dir}}/{{story_key}}.context.xml</action>

    <check if="sub-agent reports error or context file not found">
      <output>❌ HALT: Story context creation failed

Please review the error and resolve manually before re-running run-story.
      </output>
      <action>HALT</action>
    </check>

    <output>✅ Story context created: {{story_key}}.context.xml

Phase 3: Development & Review Cycles...
    </output>
  </step>

  <step n="4" goal="Execute dev-story and codex-code-review loop" tag="dev-review-loop">
    <action>Set loop_active = true</action>
    <action>Set story_complete = false</action>

    <loop while="loop_active == true AND current_iteration < {{max_iterations}}">
      <action>Increment iteration counter: current_iteration += 1</action>

      <output>🔄 Iteration {{current_iteration}}/{{max_iterations}}

─────────────────────────────
Phase 3.{{current_iteration}}a: Development
─────────────────────────────
      </output>

      <!-- Execute dev-story -->
      <action>Launch Task sub-agent with:
        - subagent_type: "general-purpose"
        - model: {{dev_model}}
        - description: "Develop story {{story_key}}"
        - prompt: "Execute the following slash command to develop story {{story_key}}: /bmad:bmm:workflows:dev-story

Pass parameters:
- story_file: {{story_file}}

Complete all implementation tasks, write tests, and validate acceptance criteria.

Report if the story is:
1. COMPLETE - All ACs met, all tests passing, ready for final review
2. BLOCKED - Cannot proceed due to missing dependencies, unclear requirements, or external blockers
3. IN_PROGRESS - Making progress but not yet complete"
      </action>

      <action>Wait for sub-agent completion</action>
      <action>Capture sub-agent output and status</action>

      <check if="sub-agent reports error or failure">
        <output>❌ HALT: Development cycle failed

**Failed at:** Iteration {{current_iteration}}
**Story:** {{story_key}}
**Error Details:** {{sub_agent_error}}

Please resolve the issue manually before re-running run-story.
        </output>
        <action>HALT</action>
      </check>

      <!-- Check if story is blocked -->
      <check if="sub-agent output contains 'BLOCKED' OR 'blocked' OR 'cannot proceed'">
        <output>⚠️ Story Development BLOCKED

**Story:** {{story_key}}
**Iteration:** {{current_iteration}}
**Reason:** {{blocker_reason}}

Development halted. Please resolve blockers manually and re-run run-story or continue with /bmad:bmm:agents:dev.
        </output>
        <action>Set loop_active = false</action>
        <action>HALT</action>
      </check>

      <!-- Check if story is complete -->
      <check if="sub-agent output contains 'COMPLETE' OR 'story complete' OR 'all ACs met'">
        <output>✅ Development reports story complete

Proceeding to final code review...
        </output>
        <action>Set story_complete = true</action>
      </check>

      <output>─────────────────────────────
Phase 3.{{current_iteration}}b: Code Review
─────────────────────────────
      </output>

      <!-- Check if codex is available, fall back to review-story if not -->
      <action>Check if 'codex' command is available: which codex OR codex --version</action>
      <action>Store codex_available = true if command succeeds, false otherwise</action>

      <check if="codex_available == true">
        <output>🔍 Using Codex for code review...</output>

        <!-- Execute codex-code-review -->
        <action>Launch Task sub-agent with:
          - subagent_type: "general-purpose"
          - model: {{review_model}}
          - description: "Review story {{story_key}} with Codex"
          - prompt: "Execute the following slash command to review story {{story_key}}: /bmad:core:workflows:codex-code-review

Pass parameters:
- story_file: {{story_file}}

Complete the code review and clearly indicate:
- '✅ PASS' if all acceptance criteria are met, tests passing, code quality excellent
- '⚠️ CHANGES REQUIRED' if issues found that need fixing

Provide specific, actionable feedback for any required changes."
        </action>
      </check>

      <check if="codex_available == false">
        <output>ℹ️ Codex not available - using review-story workflow instead...</output>

        <!-- Execute review-story as fallback -->
        <action>Launch Task sub-agent with:
          - subagent_type: "general-purpose"
          - model: {{review_model}}
          - description: "Review story {{story_key}}"
          - prompt: "Execute the following slash command to review story {{story_key}}: /bmad:bmm:workflows:review-story

Pass parameters:
- story_file: {{story_file}}

Complete the code review and clearly indicate:
- '✅ PASS' if all acceptance criteria are met, tests passing, code quality excellent
- '⚠️ CHANGES REQUIRED' if issues found that need fixing

Provide specific, actionable feedback for any required changes."
        </action>
      </check>

      <action>Wait for sub-agent completion</action>
      <action>Capture review output and verdict</action>

      <check if="sub-agent reports error">
        <output>❌ HALT: Code review failed

**Failed at:** Iteration {{current_iteration}}
**Story:** {{story_key}}
**Error Details:** {{review_error}}

Please resolve the issue manually.
        </output>
        <action>HALT</action>
      </check>

      <!-- Parse review verdict -->
      <check if="review output contains '✅ PASS'">
        <output>✅ Code Review PASSED

Story {{story_key}} has passed all quality checks!

Proceeding to commit phase...
        </output>
        <action>Set story_complete = true</action>
        <action>Set loop_active = false</action>
      </check>

      <check if="review output contains '⚠️ CHANGES REQUIRED' AND story_complete == false">
        <output>⚠️ Code Review requires changes

**Iteration {{current_iteration}} Summary:**
- Development: In progress
- Review: Changes required

Cycling back to development phase...
        </output>
        <!-- Continue loop for another dev cycle -->
      </check>

      <check if="review output contains '⚠️ CHANGES REQUIRED' AND story_complete == true">
        <output>⚠️ Development reported complete but review found issues

This indicates a mismatch between dev completion criteria and review standards.

**Iteration {{current_iteration}} Summary:**
- Development: Claimed complete
- Review: Changes required

Cycling back to development phase with review feedback...
        </output>
        <action>Set story_complete = false</action>
        <!-- Continue loop for another dev cycle with review feedback -->
      </check>

      <check if="current_iteration >= {{max_iterations}}">
        <output>⚠️ HALT: Maximum iteration limit reached

Story {{story_key}} did not complete within {{max_iterations}} iterations.
This is a safety mechanism to prevent infinite loops.

**Current State:**
- Iterations completed: {{current_iteration}}
- Story status: {{story_complete ? 'Complete but review pending' : 'In progress'}}

**Recommendations:**
1. Review {{story_file}} to see current state
2. Check last code review feedback
3. Manually complete remaining work with /bmad:bmm:agents:dev
4. Increase max_iterations parameter if needed
        </output>
        <action>Set loop_active = false</action>
        <action>HALT</action>
      </check>
    </loop>

    <output>✅ Development & Review Loop Complete

Total iterations: {{current_iteration}}
Story status: Complete and reviewed

Phase 4: Committing changes...
    </output>
  </step>

  <step n="5" goal="Commit all changes with story details" tag="commit">
    <action>Load {{story_file}} to extract story title and summary</action>
    <action>Extract story title from markdown frontmatter or first heading</action>
    <action>Get git status to see all changed files</action>
    <action>Stage all changes: git add .</action>

    <action>Create commit message with format:
      "feat(epic-{{epic_number}}): {{story_title}}

Story: {{story_key}}

{{story_summary}}

- All acceptance criteria met
- Tests passing
- Code reviewed and approved

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude &lt;noreply@anthropic.com&gt;"
    </action>

    <action>Execute commit using heredoc format:
      git commit -m "$(cat &lt;&lt;'EOF'
      {{commit_message}}
      EOF
      )"
    </action>

    <action>Run git status to verify commit</action>

    <check if="git commit failed">
      <output>❌ WARNING: Commit failed

Story development completed successfully but commit failed.
Please commit changes manually.

**Reason:** {{commit_error}}
      </output>
      <!-- Continue to update docs even if commit fails -->
    </check>

    <output>✅ Changes committed

Phase 5: Updating BMAD documentation...
    </output>
  </step>

  <step n="6" goal="Update BMAD documentation" tag="update-docs">
    <action>Load {{sprint_status_file}}</action>
    <action>Find story {{story_key}} in sprint status</action>
    <action>Update story status from current to "done"</action>
    <action>Save {{sprint_status_file}}</action>

    <action>Load {{story_file}}</action>
    <action>Update status field to "done" in story frontmatter/metadata</action>
    <action>Add completion timestamp</action>
    <action>Save {{story_file}}</action>

    <action>Load {{workflow_status_file}}</action>
    <action>Update STORIES_DONE list to include {{story_key}}</action>
    <action>Update TODO_STORY to next story in queue (if any)</action>
    <action>Update NEXT_COMMAND based on workflow logic:
      - If more stories in epic: "/bmad:bmm:workflows:run-story" or "/bmad:bmm:workflows:create-story"
      - If epic complete: "/bmad:bmm:workflows:retrospective"
      - If no more work: "Epic {{epic_number}} complete"
    </action>
    <action>Update NEXT_ACTION description accordingly</action>
    <action>Save {{workflow_status_file}}</action>

    <check if="any doc update failed">
      <output>⚠️ WARNING: Some documentation updates failed

Story completed successfully but BMAD docs may be out of sync.
Please review and update manually:
- {{sprint_status_file}}
- {{story_file}}
- {{workflow_status_file}}
      </output>
    </check>

    <output>✅ BMAD documentation updated

All project tracking files synchronized.
    </output>
  </step>

  <step n="7" goal="Output completion summary" tag="summary">
    <output>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Story Complete - {{story_key}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Story:** {{story_title}}
**Epic:** {{epic_number}}
**Iterations:** {{current_iteration}}

✅ Drafted, contexted, developed, reviewed, committed, and documented.
    </output>

    <action>END workflow with success</action>
  </step>

</workflow>
```

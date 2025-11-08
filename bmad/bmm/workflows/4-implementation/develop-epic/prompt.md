# Develop Epic - Workflow Instructions

```xml
<critical>The workflow execution engine is governed by: {project-root}/bmad/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {installed_path}/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>Generate all documents in {document_output_language}</critical>
<critical>Execute ALL steps in exact order; do NOT skip steps</critical>
<critical>User skill level ({user_skill_level}) affects conversation style ONLY, not workflow execution.</critical>

<workflow>

  <step n="1" goal="Validate parameters and initialize">
    <check if="{{epic_number}} is empty or not provided">
      <output>❌ ERROR: epic_number parameter is required

Usage: Provide epic number (e.g., epic_number: "4") when invoking this workflow.
      </output>
      <action>HALT</action>
    </check>

    <action>Store epic_number for reference: Epic {{epic_number}}</action>
    <action>Initialize iteration counter: current_iteration = 0</action>
    <action>Initialize previous_command tracker: previous_command = ""</action>
    <action>Load {{status_file}} and extract STORIES_DONE list</action>
    <action>Initialize stories_done_count with current count from STORIES_DONE</action>

    <output>🚀 Develop Epic {{epic_number}} - Autonomous Orchestration Started

Configuration:
- Epic: {{epic_number}}
- Max Iterations: {{max_iterations}}
- Status File: {{status_file}}
- Dev Model: {{dev_model}}
- Review Model: {{review_model}}

Beginning orchestration loop...
    </output>
  </step>

  <step n="2" goal="Read workflow status and extract next action" tag="status-check">
    <action>Increment iteration counter: current_iteration += 1</action>

    <check if="current_iteration > {{max_iterations}}">
      <output>⚠️ HALT: Maximum iteration limit reached ({{max_iterations}})

Epic {{epic_number}} development did not complete within iteration limit.
This is a safety mechanism to prevent infinite loops.

**Current State:**
- Iterations completed: {{current_iteration - 1}}
- Last command executed: {{previous_command}}

**Recommendations:**
1. Review {{status_file}} to see current state
2. Check if there are blockers preventing progress
3. Manually execute remaining steps
4. Increase max_iterations parameter if needed
      </output>
      <action>HALT</action>
    </check>

    <action>Load COMPLETE file: {{status_file}}</action>
    <action>Parse all sections to understand project state</action>
    <action>Extract NEXT_COMMAND value from "Next Action" section</action>
    <action>Extract NEXT_ACTION description for context</action>
    <action>Store current_command = NEXT_COMMAND value</action>

    <check if="NEXT_COMMAND is empty or missing">
      <output>⚠️ HALT: No NEXT_COMMAND found in status file

Epic {{epic_number}} orchestration cannot proceed without a defined next action.

**Completed:**
- Iterations: {{current_iteration}}
- Last command: {{previous_command}}

Check {{status_file}} to verify workflow status.
      </output>
      <action>HALT</action>
    </check>

    <check if="current_command == previous_command AND current_iteration > 1">
      <output>⚠️ HALT: Workflow status unchanged after previous iteration

Epic {{epic_number}} appears to be blocked or stuck.

**Details:**
- Iteration: {{current_iteration}}
- Command: {{current_command}}
- Status: No progress detected

**Possible Causes:**
1. Previous sub-agent encountered an error
2. Workflow requires manual intervention
3. Status file was not updated by previous step

Check {{status_file}} and logs from previous iteration.
      </output>
      <action>HALT</action>
    </check>

    <output>📋 Iteration {{current_iteration}}/{{max_iterations}}

**Next Action:** {{NEXT_ACTION}}
**Command:** {{current_command}}

Launching sub-agent...
    </output>
  </step>

  <step n="3" goal="Verify story readiness and execute command" tag="orchestration">
    <action>Load sprint-status.yaml file from {project-root}/docs/sprint-status.yaml</action>
    <action>Extract TODO_STORY value from {{status_file}}</action>
    <action>Check status of TODO_STORY in sprint-status.yaml</action>

    <check if="current_command contains 'dev-story' AND story status is 'drafted'">
      <output>⚠️ Story not ready for development

Story {{TODO_STORY}} is in 'drafted' status but needs 'ready-for-dev' status.

**Auto-fixing:** Running story-ready workflow to prepare story...
      </output>
      <action>Update {{status_file}}: change NEXT_COMMAND to '/bmad:bmm:workflows:story-ready'</action>
      <action>Update {{status_file}}: change NEXT_ACTION to 'Mark story {{TODO_STORY}} ready for development'</action>
      <output>✅ Status updated. Will mark story ready in next iteration...</output>
      <action>Update previous_command = current_command</action>
      <action><goto step="4">Check completion status</goto></action>
    </check>

    <action>Determine appropriate model based on command type:
      - If command contains "review": use {{review_model}}
      - If command contains "story-context": use {{review_model}}
      - Otherwise: use {{dev_model}}
    </action>

    <action>Store selected_model for this iteration</action>

    <output>🤖 Executing: {{current_command}}
Model: {{selected_model}}
    </output>

    <check if="current_command contains 'story-context'">
      <action>Launch Task sub-agent with:
        - subagent_type: "general-purpose"
        - model: {{selected_model}}
        - description: "Execute {{current_command}}"
        - prompt: "Execute the following slash command and complete all required steps: {{current_command}}

IMPORTANT: If the workflow asks whether to replace an existing context file, automatically choose 'replace' without prompting the user."
      </action>
    </check>

    <check if="current_command does not contain 'story-context'">
      <action>Launch Task sub-agent with:
        - subagent_type: "general-purpose"
        - model: {{selected_model}}
        - description: "Execute {{current_command}}"
        - prompt: "Execute the following slash command and complete all required steps: {{current_command}}"
      </action>
    </check>

    <action>Wait for sub-agent completion</action>
    <action>Capture sub-agent result and any error messages</action>

    <check if="sub-agent reports error or failure">
      <output>❌ HALT: Sub-agent execution failed

Epic {{epic_number}} orchestration halted due to error in iteration {{current_iteration}}.

**Failed Command:** {{current_command}}
**Model Used:** {{selected_model}}
**Error Details:** {{sub_agent_error}}

Please resolve the issue manually before re-running develop-epic.
      </output>
      <action>HALT</action>
    </check>

    <output>✅ Command completed successfully

Iteration {{current_iteration}} finished. Checking for next action...
    </output>

    <action>Update previous_command = current_command</action>
  </step>

  <step n="4" goal="Check completion status and commit changes" tag="status-check">
    <action>Re-read {{status_file}} to get updated state</action>
    <action>Extract new NEXT_COMMAND value</action>
    <action>Extract new STORIES_DONE list from status file</action>
    <action>Check if epic {{epic_number}} is marked complete in status file</action>

    <action>Store new_stories_done_count = length of STORIES_DONE list</action>
    <action>Compare: if new_stories_done_count > stories_done_count, a story was just completed</action>

    <check if="new_stories_done_count > stories_done_count">
      <output>✅ Story completed! Creating git commit...

Stories completed: {{STORIES_DONE}}
      </output>

      <action>Check if feature branch exists: git branch --list "epic-{{epic_number}}"</action>

      <check if="branch does not exist">
        <action>Create and checkout feature branch: git checkout -b epic-{{epic_number}}</action>
        <output>📦 Created feature branch: epic-{{epic_number}}</output>
      </check>

      <check if="branch exists but not checked out">
        <action>Checkout feature branch: git checkout epic-{{epic_number}}</action>
      </check>

      <action>Get last completed story ID from STORIES_DONE list</action>
      <action>Read story markdown file to extract story title</action>
      <action>Stage all changes: git add .</action>
      <action>Create descriptive commit with story details using heredoc format</action>
      <action>Run git status to verify commit</action>

      <output>✅ Changes committed to epic-{{epic_number}} branch</output>

      <action>Reset iteration counter: current_iteration = 0</action>
      <action>Update stories_done_count = new_stories_done_count</action>
    </check>

    <check if="epic {{epic_number}} is marked complete OR no more actions for this epic">
      <output>🎉 Epic {{epic_number}} Development Complete!

**Summary:**
- Total iterations for last story: {{current_iteration}}
- Final status: Complete
- All workflow actions executed successfully

Creating pull request...
      </output>

      <action>Ensure we're on epic-{{epic_number}} branch</action>
      <action>Push branch to remote: git push -u origin epic-{{epic_number}}</action>
      <action>Read epic context file to extract epic title and description</action>
      <action>Get list of all commits on this branch: git log main..HEAD --oneline</action>
      <action>Create PR body with:
        - Epic summary from context
        - List of completed stories with titles
        - Test summary
        - Changes summary
      </action>
      <action>Create PR using gh pr create with heredoc format for body</action>
      <action>Capture PR URL from gh output</action>

      <output>✅ Pull Request Created!

**Epic {{epic_number}} Summary:**
- Stories completed: {{STORIES_DONE}}
- PR URL: {{pr_url}}

**Next Steps:**
1. Review the pull request
2. Run retrospective workflow if desired
3. Merge PR after approval
      </output>
      <action>END workflow with success</action>
    </check>

    <check if="NEXT_COMMAND changed (not equal to previous_command)">
      <output>🔄 Status updated - continuing to next action

Iteration {{current_iteration}} complete. Proceeding to iteration {{current_iteration + 1}}...
      </output>
      <action><goto step="2">Next iteration</goto></action>
    </check>

    <check if="NEXT_COMMAND unchanged AND current_iteration >= {{max_iterations}}">
      <output>⚠️ HALT: Maximum iterations reached with unchanged status

See iteration limit halt message from step 2.
      </output>
      <action>HALT</action>
    </check>

    <output>⚠️ Unexpected state - status file appears unchanged but epic not complete

Halting to prevent infinite loop. Manual intervention required.
    </output>
    <action>HALT</action>
  </step>

</workflow>
```

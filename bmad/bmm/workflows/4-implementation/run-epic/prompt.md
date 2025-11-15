# Run Epic - Workflow Instructions

```xml
<critical>The workflow execution engine is governed by: {project-root}/bmad/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {installed_path}/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>Generate all documents in {document_output_language}</critical>
<critical>Execute ALL steps in exact order; do NOT skip steps</critical>
<critical>User skill level ({user_skill_level}) affects conversation style ONLY, not workflow execution.</critical>

<workflow>

  <step n="1" goal="Validate parameters and initialize">
    <!-- If epic_id is empty, prompt user to select -->
    <check if="{{epic_id}} is empty or not provided">
      <output>📋 No epic specified - loading available epics...</output>

      <action>Load {{sprint_status_file}}</action>
      <action>Parse development_status section</action>
      <action>Extract all epic entries (lines matching pattern "epic-N:" or "epic-N-name:")</action>
      <action>For each epic, count pending stories (stories not in "done" status)</action>
      <action>Filter to epics with at least one pending story</action>

      <check if="no epics found">
        <output>ℹ️ No epics found in sprint status

**Options:**
1. Run sprint-planning to initialize: /bmad:bmm:workflows:sprint-planning
2. Provide epic_id parameter explicitly (e.g., epic_id: "5")
        </output>
        <action>HALT</action>
      </check>

      <check if="no epics with pending stories">
        <output>🎉 All epics complete!

All stories in all epics are marked as "done".

{{for each epic}}
- Epic {{epic_number}}: ✅ Complete ({{story_count}} stories)
{{end}}

No work remaining. Consider running retrospectives or starting a new epic.
        </output>
        <action>HALT</action>
      </check>

      <output>📋 Available Epics (with pending work):

{{for each epic with pending stories}}
  {{epic_index}}. Epic {{epic_id}}: {{epic_title}} ({{pending_count}}/{{total_count}} pending)
{{end}}

Please select an epic by number (or provide epic_id parameter).
      </output>

      <action>WAIT for user input</action>
      <action>User selects epic by number OR provides epic_id</action>
      <action>Parse user input to determine selected epic</action>
      <action>Set epic_id = {{selected_epic_id}}</action>

      <output>✅ Selected: Epic {{epic_id}}</output>
    </check>

    <!-- Now we should have epic_id -->
    <check if="{{epic_id}} is still empty">
      <output>❌ ERROR: Cannot determine epic ID

Please provide epic_id parameter or select from available epics.
      </output>
      <action>HALT</action>
    </check>

    <action>Store epic_id for reference: Epic {{epic_id}}</action>
    <action>Initialize story counter: stories_completed = 0</action>
    <action>Initialize story list: all_stories = []</action>
    <action>Initialize story list: pending_stories = []</action>

    <output>🚀 Run Epic {{epic_id}} - Complete Epic Lifecycle Automation Started

Configuration:
- Epic ID: {{epic_id}}
- Max Stories: {{max_stories}}
- Dev Model: {{dev_model}}
- Review Model: {{review_model}}
- Create PR: {{create_pr}}

Phase 1: Loading sprint status and discovering stories...
    </output>
  </step>

  <step n="2" goal="Load sprint status and extract stories for epic" tag="discover-stories">
    <action>Load {{sprint_status_file}}</action>
    <action>Parse YAML structure</action>
    <action>Extract development_status section</action>

    <check if="file not found or parse error">
      <output>❌ HALT: Cannot load sprint status file

**File:** {{sprint_status_file}}

Please ensure sprint-status.yaml exists and is valid YAML.
You may need to run /bmad:bmm:workflows:sprint-planning first.
      </output>
      <action>HALT</action>
    </check>

    <action>Look for epic entry: "epic-{{epic_id}}: [status]"</action>

    <check if="epic entry not found">
      <output>❌ HALT: Epic {{epic_id}} not found in sprint status

**Available epics in sprint-status.yaml:**
{{list_of_epic_entries}}

Please verify the epic_id parameter or run sprint-planning to update status file.
      </output>
      <action>HALT</action>
    </check>

    <action>Find all story entries matching patterns:
      - "e{{epic_id}}-" (e.g., "e5-1-...", "e5-2-...")
      - "{{epic_id}}-" (e.g., "5-1-...", "5-2-...")
    </action>

    <action>For each matching story entry:
      - Extract story key (full name before colon)
      - Extract status (value after colon)
      - Add to all_stories list
      - If status != "done", add to pending_stories list
    </action>

    <check if="all_stories is empty">
      <output>⚠️ HALT: No stories found for Epic {{epic_id}}

Epic exists in sprint status but has no associated stories.

**Recommendations:**
1. Check if stories are defined in the epic file
2. Run sprint-planning workflow to refresh status
3. Create stories using /bmad:bmm:workflows:create-story
      </output>
      <action>HALT</action>
    </check>

    <check if="pending_stories is empty">
      <output>🎉 Epic {{epic_id}} Already Complete!

All stories for this epic are marked as "done".

**Total Stories:** {{all_stories.length}}
**Completed:** {{all_stories.length}}

No work remaining. Epic is ready for retrospective or PR creation.
      </output>
      <action><goto step="6">Skip to PR creation</goto></action>
    </check>

    <output>✅ Epic Discovery Complete

**Epic {{epic_id}} Status:**
- Total Stories: {{all_stories.length}}
- Completed: {{all_stories.length - pending_stories.length}}
- Pending: {{pending_stories.length}}

**Pending Stories:**
{{for each story in pending_stories}}
  - {{story.key}} ({{story.status}})
{{end}}

Phase 2: Processing pending stories...
    </output>
  </step>

  <step n="3" goal="Process each pending story" tag="process-stories">
    <action>Initialize current_story_index = 0</action>

    <loop while="current_story_index < pending_stories.length">
      <action>Get current_story = pending_stories[current_story_index]</action>
      <action>Extract epic_number and story_number from current_story.key</action>
      <action>Parse story key pattern (e.g., "e5-2-..." or "5-2-..."):
        - If starts with "e": epic_number = {{epic_id}}, extract story_number after first dash
        - If starts with digit: epic_number = first number, story_number = second number
      </action>

      <output>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📖 Story {{current_story_index + 1}}/{{pending_stories.length}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Story:** {{current_story.key}}
**Current Status:** {{current_story.status}}
**Epic:** {{epic_number}}
**Story Number:** {{story_number}}

Launching run-story workflow...
      </output>

      <action>Launch Task sub-agent with:
        - subagent_type: "general-purpose"
        - model: {{review_model}}
        - description: "Complete story {{current_story.key}}"
        - prompt: "Execute the run-story workflow for Epic {{epic_number}}, Story {{story_number}}:

/bmad:bmm:workflows:run-story

Parameters:
- epic_number: {{epic_number}}
- story_number: {{story_number}}

Complete the entire story lifecycle: draft, context, develop with alternating dev/review cycles, commit, and update docs.

If the story is already drafted and has context, the workflow will skip those phases and proceed to development.

Report final status as one of:
- COMPLETE: Story finished successfully
- BLOCKED: Story cannot proceed (provide reason)
- ERROR: Unexpected error occurred (provide details)"
      </action>

      <action>Wait for sub-agent completion</action>
      <action>Capture sub-agent output and status</action>

      <check if="sub-agent output contains 'BLOCKED' OR 'blocked'">
        <output>⚠️ Story BLOCKED - Epic Processing Halted

**Story:** {{current_story.key}}
**Story:** {{current_story_index + 1}}/{{pending_stories.length}}
**Reason:** {{blocker_reason}}

**Epic {{epic_id}} Progress:**
- Stories Completed This Run: {{stories_completed}}
- Stories Remaining: {{pending_stories.length - current_story_index}}

Epic processing halted due to blocker. Please resolve and re-run run-epic.
        </output>
        <action>HALT</action>
      </check>

      <check if="sub-agent reports error or failure">
        <output>❌ HALT: Story execution failed

**Story:** {{current_story.key}}
**Position:** {{current_story_index + 1}}/{{pending_stories.length}}
**Error:** {{error_details}}

**Epic {{epic_id}} Progress:**
- Stories Completed This Run: {{stories_completed}}
- Stories Remaining: {{pending_stories.length - current_story_index}}

Please resolve the error manually before re-running run-epic.
        </output>
        <action>HALT</action>
      </check>

      <check if="sub-agent output contains 'COMPLETE' OR 'Story Complete'">
        <output>✅ Story {{current_story.key}} Complete

Successfully finished {{stories_completed + 1}}/{{pending_stories.length}} stories in this run.
        </output>
        <action>Increment stories_completed</action>
      </check>

      <action>Increment current_story_index</action>

      <check if="current_story_index < pending_stories.length">
        <output>
Proceeding to next story...
        </output>
      </check>
    </loop>

    <output>✅ All Pending Stories Processed

**Epic {{epic_id}} Results:**
- Total Stories Completed: {{stories_completed}}
- Total Stories in Epic: {{all_stories.length}}

Phase 3: Finalizing epic...
    </output>
  </step>

  <step n="4" goal="Reload sprint status and verify epic completion" tag="verify-completion">
    <action>Reload {{sprint_status_file}} to get latest state</action>
    <action>Re-extract all stories for Epic {{epic_id}}</action>
    <action>Count stories with status = "done"</action>
    <action>Count total stories for epic</action>

    <action>Store done_count and total_count</action>

    <check if="done_count < total_count">
      <output>⚠️ Epic {{epic_id}} Incomplete

**Status:**
- Completed: {{done_count}}/{{total_count}}
- Remaining: {{total_count - done_count}}

**Remaining Stories:**
{{list stories not marked done}}

Run run-epic again to continue, or complete remaining stories manually.
      </output>
      <action>END workflow (epic incomplete but progress made)</action>
    </check>

    <output>🎉 Epic {{epic_id}} Complete!

**Final Status:**
- Total Stories: {{total_count}}
- All stories marked as "done"

Phase 4: Creating commit and pull request...
    </output>
  </step>

  <step n="5" goal="Create feature branch and pull request" tag="create-pr">
    <check if="{{create_pr}} == false">
      <output>✅ Epic {{epic_id}} Complete

Pull request creation disabled (create_pr: false).

Manual steps:
1. Review changes with: git status
2. Create feature branch if needed: git checkout -b epic-{{epic_id}}
3. Create PR manually when ready
      </output>
      <action><goto step="7">Skip to summary</goto></action>
    </check>

    <action>Check current git branch</action>

    <check if="not on feature branch epic-{{epic_id}}">
      <action>Check if epic-{{epic_id}} branch exists</action>

      <check if="branch does not exist">
        <action>Create and checkout feature branch: git checkout -b epic-{{epic_id}}</action>
        <output>📦 Created feature branch: epic-{{epic_id}}</output>
      </check>

      <check if="branch exists but not checked out">
        <action>Checkout feature branch: git checkout epic-{{epic_id}}</action>
        <output>📦 Switched to feature branch: epic-{{epic_id}}</output>
      </check>
    </check>

    <action>Check if there are uncommitted changes: git status --porcelain</action>

    <check if="uncommitted changes exist">
      <output>⚠️ Uncommitted changes detected

This shouldn't happen if all stories were properly committed.
Committing remaining changes now...
      </output>

      <action>Stage all changes: git add .</action>
      <action>Create commit with epic summary using heredoc format</action>
      <action>Run git status to verify commit</action>
    </check>

    <action>Push branch to remote: git push -u origin epic-{{epic_id}}</action>

    <action>Find epic file: {output_folder}/epic-{{epic_id}}.md OR {output_folder}/epic{{epic_id}}.md</action>
    <action>Read epic file to extract title and description</action>

    <action>Get list of all commits on this branch: git log main..HEAD --oneline</action>
    <action>Extract story titles from commits</action>

    <action>Create PR body with:
      - Epic title and summary
      - List of completed stories ({{total_count}} stories)
      - Link to epic file
      - Test summary (all tests passing)
      - Changes overview
    </action>

    <action>Create PR using gh pr create with heredoc format:
      gh pr create --title "Epic {{epic_id}}: {{epic_title}}" --body "$(cat &lt;&lt;'EOF'
      ## Epic {{epic_id}}: {{epic_title}}

      {{epic_description}}

      ### Completed Stories ({{total_count}})

      {{for each story in all_stories}}
      - [x] {{story.key}}: {{story.title}}
      {{end}}

      ### Testing

      All acceptance criteria met and tests passing for all stories.

      ### Changes

      {{commit_summary}}

      ---
      🤖 Generated with [Claude Code](https://claude.com/claude-code)

      Co-Authored-By: Claude &lt;noreply@anthropic.com&gt;
      EOF
      )"
    </action>

    <action>Capture PR URL from gh output</action>

    <check if="PR creation failed">
      <output>⚠️ WARNING: Pull request creation failed

Epic completed successfully but PR creation failed.

**Reason:** {{pr_error}}

Create PR manually with:
  git checkout epic-{{epic_id}}
  gh pr create
      </output>
      <action><goto step="7">Skip to summary</goto></action>
    </check>

    <output>✅ Pull Request Created

**PR URL:** {{pr_url}}

Phase 5: Updating BMAD documentation...
    </output>
  </step>

  <step n="6" goal="Update BMAD documentation" tag="update-docs">
    <action>Load {{workflow_status_file}}</action>

    <action>Update for epic completion:
      - Clear TODO_STORY if it was from this epic
      - Update NEXT_COMMAND to suggest retrospective:
        "/bmad:bmm:workflows:retrospective" if retrospective not done
      - Update NEXT_ACTION description
    </action>

    <action>Save {{workflow_status_file}}</action>

    <check if="workflow status update failed">
      <output>⚠️ WARNING: Workflow status update failed

Epic completed but workflow-status.md may be out of sync.
Please review and update manually.
      </output>
    </check>

    <output>✅ BMAD documentation updated
    </output>
  </step>

  <step n="7" goal="Output completion summary" tag="summary">
    <output>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Epic {{epic_id}} Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Epic Summary:**
- Total Stories: {{total_count}}
- Stories Completed This Run: {{stories_completed}}
- All Stories: ✅ Done

{{if create_pr AND pr_url}}
**Pull Request:**
{{pr_url}}
{{end}}

**Next Steps:**
1. Review and merge the pull request
{{if retrospective not done}}
2. Consider running retrospective: /bmad:bmm:workflows:retrospective
{{end}}
3. Celebrate! 🎊

✅ Epic {{epic_id}} successfully delivered.
    </output>

    <action>END workflow with success</action>
  </step>

</workflow>
```

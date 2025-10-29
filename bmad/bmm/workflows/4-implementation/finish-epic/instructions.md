# Finish Epic - Workflow Instructions

```xml
<critical>The workflow execution engine is governed by: {project-root}/bmad/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {installed_path}/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>Execute ALL steps in exact order; do NOT skip steps</critical>
<critical>This is an ORCHESTRATION workflow - you coordinate sub-agent execution, not direct implementation</critical>

<workflow>

  <step n="1" goal="Load sprint status and identify target epic" tag="epic-discovery">
    <critical>MUST read COMPLETE sprint-status.yaml file to preserve story order</critical>
    <action>Load the FULL file: {{sprint_status_file}}</action>
    <action>Read ALL lines from beginning to end - do not skip any content</action>
    <action>Parse the development_status section completely</action>

    <check if="{{epic_key}} is provided">
      <action>Use {{epic_key}} as target epic</action>
      <action>Verify epic exists in sprint-status.yaml</action>
      <check if="epic not found">
        <output>❌ Epic {{epic_key}} not found in sprint status file</output>
        <action>HALT</action>
      </check>
    </check>

    <check if="{{epic_key}} is NOT provided">
      <action>Find the FIRST epic with at least one story that is NOT in "done" status</action>
      <action>Store as {{epic_key}}</action>
      <check if="no epic with pending stories found">
        <output>✅ All epics are complete! No pending stories found.
**Next steps:**
- Run `retrospective` workflow for any epic marked "optional"
- Consider starting a new epic or project phase
        </output>
        <action>HALT</action>
      </check>
    </check>

    <output>🎯 **Target Epic:** {{epic_key}}
📊 **Sprint Status File:** {{sprint_status_file}}
    </output>
  </step>

  <step n="1.5" goal="Create epic branch for development" tag="git-branch">
    <action>Get current git branch name and store as {{original_branch}}</action>
    <action>Generate epic branch name: epic/{{epic_key}}</action>
    <action>Check if branch epic/{{epic_key}} already exists</action>

    <check if="branch exists">
      <output>🔀 **Epic branch already exists**
Branch: epic/{{epic_key}}

Switching to existing epic branch for continued development.
      </output>
      <action>Switch to branch epic/{{epic_key}}</action>
    </check>

    <check if="branch does NOT exist">
      <output>🌿 **Creating new epic branch**
Branch: epic/{{epic_key}}
Base: {{original_branch}}
      </output>
      <action>Create new branch epic/{{epic_key}} from {{original_branch}}</action>
      <action>Switch to branch epic/{{epic_key}}</action>
    </check>

    <output>✅ **Working on branch:** epic/{{epic_key}}</output>
  </step>

  <step n="2" goal="Build ordered story queue for epic" tag="story-queue">
    <action>Extract ALL story keys belonging to {{epic_key}} from development_status section</action>
    <action>Filter to stories matching pattern: {{epic_key}}-number-name (e.g., "e3-1-integrate-droptarget")</action>
    <action>Preserve the EXACT order from sprint-status.yaml (top to bottom)</action>
    <action>Create story_queue list maintaining file order</action>
    <action>For each story in queue, capture: story_key, current_status, file_path</action>

    <check if="{{story_key}} is provided (starting story specified)">
      <action>Find {{story_key}} position in story_queue</action>
      <check if="{{story_key}} not found in epic">
        <output>❌ Story {{story_key}} does not belong to epic {{epic_key}}</output>
        <action>HALT</action>
      </check>
      <action>Trim story_queue to start from {{story_key}} position (inclusive)</action>
      <output>🔄 **Starting from story:** {{story_key}}</output>
    </check>

    <action>Filter story_queue to exclude stories with status "done"</action>
    <action>Store filtered queue as {{pending_stories}}</action>

    <check if="{{pending_stories}} is empty">
      <output>✅ **Epic {{epic_key}} is complete!** All stories are done.
**Next steps:**
- Run `retrospective` workflow for this epic
- Move to next epic or phase
      </output>
      <action>HALT</action>
    </check>

    <output>📝 **Stories to process:** {{pending_stories.length}}

**Story Queue:**
{{for each story in pending_stories}}
- [{{story.current_status}}] {{story.story_key}}
{{end}}

**Processing Strategy:**
- Sequential execution (one story at a time)
- Auto-retry on review feedback (max {{max_review_retry_cycles}} cycles)
- Auto-advance on completion: {{auto_advance_on_success}}
    </output>
  </step>

  <step n="3" goal="Process each story sequentially" tag="story-loop">
    <action>Initialize {{current_story_index}} = 0</action>
    <action>Initialize {{global_halt_flag}} = false</action>

    <loop while="{{current_story_index}} < {{pending_stories.length}} AND {{global_halt_flag}} == false">
      <action>Set {{current_story}} = {{pending_stories[current_story_index]}}</action>
      <action>Set {{retry_count}} = 0</action>
      <action>Set {{story_complete}} = false</action>

      <output>
═══════════════════════════════════════════════════════════
🚀 **Processing Story {{current_story_index + 1}} of {{pending_stories.length}}**
📌 **Story:** {{current_story.story_key}}
📊 **Current Status:** {{current_story.current_status}}
═══════════════════════════════════════════════════════════
      </output>

      <!-- Inner loop: dev-story → review-story cycle -->
      <loop while="{{story_complete}} == false AND {{retry_count}} <= {{max_review_retry_cycles}}">

        <!-- Sub-step 3.1: Execute dev-story workflow -->
        <substep n="3.1" goal="Execute dev-story via sub-agent" tag="dev-execution">
          <output>
🔧 **Executing dev-story workflow**
📂 Story: {{current_story.story_key}}
🔄 Retry cycle: {{retry_count}} of {{max_review_retry_cycles}}
          </output>

          <critical>Use Task tool with subagent_type="general-purpose" to instantiate Developer Agent (Amelia) persona</critical>
          <action>Launch Task with prompt: "You are Amelia, the Developer Agent. Load your persona from {project-root}/bmad/bmm/agents/dev.md and execute the dev-story workflow for story: {{current_story.story_key}}. Execute the workflow at: {{sub_workflows.dev_story}}/workflow.yaml. The story file path is: {{current_story.file_path}}. Follow the dev-story workflow instructions completely, implementing all tasks, writing tests, and marking the story as 'review' when complete. Return a status report indicating whether the story completed successfully or if there was a halt/error condition."</action>
          <action>Capture execution result as {{dev_result}}</action>

          <check if="{{dev_result.status}} == 'halt' OR {{dev_result.status}} == 'error'">
            <output>⚠️ **IMPEDIMENT DETECTED**

**Story:** {{current_story.story_key}}
**Phase:** Development (dev-story)
**Issue:** {{dev_result.error_message}}

**Recommended Actions:**
{{if dev_result.contains('test failure')}}
- Review test output in story Dev Agent Record
- Fix failing tests manually
- Re-run `dev-story` workflow for this story
{{else if dev_result.contains('missing dependency')}}
- Install required dependencies
- Update architecture or tech-spec if needed
- Re-run `dev-story` workflow for this story
{{else if dev_result.contains('unclear acceptance criteria')}}
- Clarify acceptance criteria in story file
- Consider running `correct-course` workflow
- Update story file and re-run `dev-story`
{{else}}
- Review story file: {{current_story.file_path}}
- Check Dev Agent Record for debug information
- Resolve impediment manually
- Re-run `finish-epic` workflow to resume
{{end}}

**To Resume:**
Run: `finish-epic` with epic_key={{epic_key}} story_key={{current_story.story_key}}
            </output>
            <action>Set {{global_halt_flag}} = true</action>
            <action>HALT</action>
          </check>

          <output>✅ Development phase complete for {{current_story.story_key}}</output>
        </substep>

        <!-- Sub-step 3.2: Execute review-story workflow -->
        <substep n="3.2" goal="Execute review-story via sub-agent" tag="review-execution">
          <output>
🔍 **Executing review-story workflow**
📂 Story: {{current_story.story_key}}
          </output>

          <critical>Use Task tool with subagent_type="general-purpose" to instantiate Senior Developer Reviewer persona</critical>
          <action>Launch Task with prompt: "You are a Senior Developer Reviewer. Load the review-story workflow from {{sub_workflows.review_story}}/workflow.yaml. Review the story at: {{current_story.file_path}}. Follow the review-story workflow instructions completely. Use the story context file, epic tech-spec, repository documentation, and perform a thorough code review. Append structured review notes to the story file. Return a status report indicating: 1) Whether the review passed (Approved/LGTM) or changes are needed, 2) Any key findings or feedback, 3) Whether there was a halt/error condition."</action>
          <action>Capture execution result as {{review_result}}</action>

          <check if="{{review_result.status}} == 'halt' OR {{review_result.status}} == 'error'">
            <output>⚠️ **IMPEDIMENT DETECTED**

**Story:** {{current_story.story_key}}
**Phase:** Review (review-story)
**Issue:** {{review_result.error_message}}

**Recommended Actions:**
- Review story file: {{current_story.file_path}}
- Check review notes in story Review section
- Resolve impediment manually
- Re-run `finish-epic` workflow to resume

**To Resume:**
Run: `finish-epic` with epic_key={{epic_key}} story_key={{current_story.story_key}}
            </output>
            <action>Set {{global_halt_flag}} = true</action>
            <action>HALT</action>
          </check>

          <!-- Parse review outcome -->
          <action>Read updated story file to check review status</action>
          <action>Parse Review section for approval status</action>

          <check if="story Review section indicates 'Approved' or 'LGTM'">
            <output>✅ **Review PASSED** - Story {{current_story.story_key}} approved</output>
            <action>Set {{story_complete}} = true</action>
          </check>

          <check if="story Review section indicates changes needed">
            <action>Increment {{retry_count}}</action>

            <check if="{{retry_count}} > {{max_review_retry_cycles}}">
              <output>⚠️ **MAX RETRY CYCLES REACHED**

**Story:** {{current_story.story_key}}
**Retry Cycles:** {{retry_count}}
**Issue:** Story has been through {{max_review_retry_cycles}} dev-review cycles without approval

**Recommended Actions:**
- Review accumulated feedback in story Review section
- Consider if story scope is too large (should be split)
- Run `correct-course` workflow to reassess approach
- Manually address complex issues
- Adjust max_review_retry_cycles if needed for complex stories

**To Resume:**
Run: `finish-epic` with epic_key={{epic_key}} story_key={{current_story.story_key}}
              </output>
              <action>Set {{global_halt_flag}} = true</action>
              <action>HALT</action>
            </check>

            <output>
🔄 **Review requires changes - initiating retry cycle {{retry_count}}**
📝 Review feedback has been captured in story file
🔧 Re-running dev-story workflow to address feedback...
            </output>
            <!-- Loop continues - will execute dev-story again -->
          </check>
        </substep>

      </loop> <!-- End dev-review retry loop -->

      <!-- Sub-step 3.3: Mark story as done -->
      <check if="{{story_complete}} == true">
        <substep n="3.3" goal="Mark story as done" tag="story-completion">
          <output>
📋 **Marking story as done**
📂 Story: {{current_story.story_key}}
          </output>

          <critical>Use Task tool with subagent_type="general-purpose" to mark story done</critical>
          <action>Launch Task with prompt: "Execute the story-done workflow from {{sub_workflows.story_done}}/workflow.yaml. Mark story {{current_story.story_key}} as done in the sprint-status.yaml file. Update: development_status['{{current_story.story_key}}'] = 'done'. Return confirmation that the status was updated successfully."</action>

          <output>✅ **Story {{current_story.story_key}} marked as DONE**</output>
        </substep>

        <!-- Sub-step 3.4: Create git commit for completed story -->
        <substep n="3.4" goal="Create beautiful git commit" tag="git-commit">
          <output>
📝 **Creating git commit for story**
📂 Story: {{current_story.story_key}}
          </output>

          <action>Read the completed story file to extract summary information</action>
          <action>Parse File List section to identify changed files</action>
          <action>Parse Acceptance Criteria section to extract key accomplishments</action>
          <action>Parse Dev Agent Record → Completion Notes for implementation highlights</action>

          <action>Craft git commit message following this format:
            Subject line (50 chars max): "Story {{story_id}}: {{brief_title}}"

            Body (wrapped at 72 chars):
            - Summary of what was implemented (2-3 sentences)
            - Key acceptance criteria met (bullet list)
            - Notable technical decisions or patterns used
            - Files created/modified/deleted (grouped by type)

            Footer:
            Story: {{current_story.story_key}}
            Epic: {{epic_key}}
          </action>

          <action>Stage all files listed in the story's File List section using git add</action>
          <action>Create commit with the crafted message</action>
          <action>Verify commit was created successfully</action>

          <output>✅ **Git commit created for {{current_story.story_key}}**</output>
        </substep>

        <!-- Advance to next story -->
        <check if="{{auto_advance_on_success}} == true">
          <action>Increment {{current_story_index}}</action>

          <check if="{{pause_between_stories}} == true AND {{current_story_index}} < {{pending_stories.length}}">
            <output>
⏸️  **Story complete - pausing before next story**

**Completed:** {{current_story.story_key}}
**Next:** {{pending_stories[current_story_index].story_key}}

**Continue processing remaining stories?**
(User can respond with 'yes' to continue or 'exit' to stop)
            </output>
            <action>WAIT for user confirmation</action>
            <check if="user response contains 'exit' or 'stop' or 'no'">
              <output>🛑 User requested stop. Workflow paused.</output>
              <action>Set {{global_halt_flag}} = true</action>
            </check>
          </check>

          <check if="{{pause_between_stories}} == false">
            <action>Increment {{current_story_index}} (already done above)</action>
            <output>
➡️  **Auto-advancing to next story**
            </output>
          </check>
        </check>
      </check>

    </loop> <!-- End story loop -->

  </step>

  <step n="4" goal="Create Pull Request for epic" tag="create-pr">
    <check if="{{global_halt_flag}} == true">
      <output>⏸️ **Workflow paused due to impediment or user request**

Resume with: `finish-epic` epic_key={{epic_key}}
      </output>
      <action>HALT</action>
    </check>

    <output>
═══════════════════════════════════════════════════════════
🎉 **EPIC {{epic_key}} COMPLETE!** 🎉
═══════════════════════════════════════════════════════════

**Stories Processed:** {{pending_stories.length}}
**All Acceptance Criteria Met:** ✅
**All Reviews Passed:** ✅
    </output>

    <substep n="4.1" goal="Generate PR summary" tag="pr-summary">
      <action>Read epic file from {{output_folder}}/epics.md to extract epic overview and context</action>
      <action>Parse epic title, description, and scope</action>
      <action>Collect summary information from all completed stories in {{pending_stories}}</action>
      <action>For each story, extract: title, key features implemented, files changed</action>

      <action>Determine semantic PR title prefix:
        - "feat:" for new features or functionality
        - "fix:" for bug fixes
        - "refactor:" for code restructuring without behavior change
        - "docs:" for documentation-only changes
        - "test:" for test additions/changes
        - "chore:" for maintenance tasks
      </action>

      <action>Craft PR title (50 chars max): "{{prefix}}: {{epic_brief_title}}"</action>

      <action>Craft detailed PR description following this format:
        ## Epic Summary
        {{epic_description}}

        ## Stories Completed
        {{for each story}}
        ### {{story_id}}: {{story_title}}
        {{story_summary}}

        **Key Changes:**
        - {{list_of_features}}

        **Files Modified:**
        - {{grouped_file_list}}
        {{end for}}

        ## Testing
        - All {{total_test_count}} tests pass
        - Zero flutter analyze warnings
        - All acceptance criteria met across all stories

        ## Epic Metrics
        - Stories: {{pending_stories.length}}
        - Files Created: {{created_files_count}}
        - Files Modified: {{modified_files_count}}
        - Total Changes: {{total_line_changes}} lines

        Epic: {{epic_key}}
      </action>
    </substep>

    <substep n="4.2" goal="Push branch and create PR" tag="github-pr">
      <output>
📤 **Pushing epic branch to remote**
Branch: epic/{{epic_key}}
      </output>

      <action>Push epic/{{epic_key}} branch to remote repository</action>
      <action>Use gh pr create command to create pull request</action>
      <action>Set PR title to crafted semantic title</action>
      <action>Set PR body to crafted detailed description</action>
      <action>Set base branch to {{original_branch}} (typically main)</action>
      <action>Capture PR URL from gh command output</action>

      <output>✅ **Pull Request Created**
🔗 {{pr_url}}

**Title:** {{pr_title}}
**Base:** {{original_branch}} ← **Head:** epic/{{epic_key}}
      </output>
    </substep>

    <substep n="4.3" goal="Final instructions" tag="next-steps">
      <output>
═══════════════════════════════════════════════════════════

**Next Steps:**
1. Review the PR at: {{pr_url}}
2. Run `retrospective` workflow for epic {{epic_key}} (optional)
3. Merge the PR when ready
4. Consider starting next epic

**Commands:**
- Review PR: Open {{pr_url}} in browser
- Retrospective: Run `retrospective` epic={{epic_key}}
- Start next epic: Run `finish-epic` (will auto-select next epic)

═══════════════════════════════════════════════════════════
      </output>
    </substep>
  </step>

</workflow>
```

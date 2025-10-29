# Make Epic Ready - Workflow Instructions

```xml
<critical>The workflow execution engine is governed by: {project-root}/bmad/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {installed_path}/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>This is an ORCHESTRATION workflow - you coordinate parallel sub-agent execution for context generation</critical>
<critical>This workflow is designed for the Scrum Master agent after user has reviewed drafted stories</critical>

<workflow>

  <step n="1" goal="Load sprint status and identify target epic with drafted stories" tag="epic-discovery">
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
      <action>Find the FIRST epic with at least one story in "drafted" status</action>
      <action>Store as {{epic_key}}</action>
      <check if="no epic with drafted stories found">
        <output>📋 No epics with drafted stories found.

**Current State:**
- All stories are either in backlog, ready-for-dev, in-progress, or done
- No drafted stories need context generation

**Next Steps:**
1. Run `create-story` to draft new stories
2. Check sprint-status.yaml to verify story states
        </output>
        <action>HALT</action>
      </check>
    </check>

    <output>🎯 **Target Epic:** {{epic_key}}
📊 **Sprint Status File:** {{sprint_status_file}}
    </output>
  </step>

  <step n="2" goal="Build list of drafted stories for epic" tag="story-collection">
    <action>Extract ALL story keys belonging to {{epic_key}} from development_status section</action>
    <action>Filter to stories matching pattern: {{epic_key}}-number-name (e.g., "e3-1-integrate-droptarget")</action>
    <action>Further filter to stories with status exactly "drafted"</action>
    <action>Preserve the EXACT order from sprint-status.yaml (top to bottom)</action>
    <action>Create {{drafted_stories}} list maintaining file order</action>
    <action>For each story in list, capture: story_key, file_path, context_file_path</action>

    <check if="{{drafted_stories}} is empty">
      <output>✅ **Epic {{epic_key}} has no drafted stories**

**Current State:**
- All stories in this epic are either in backlog, ready-for-dev, in-progress, or done
- No context generation needed

**Options:**
1. Run `create-story` to draft more stories for this epic
2. Check a different epic
3. Proceed to `finish-epic` if stories are already ready
      </output>
      <action>HALT</action>
    </check>

    <output>📝 **Drafted Stories Found:** {{drafted_stories.length}}

**Stories to Process:**
{{for each story in drafted_stories}}
- {{story.story_key}}
{{end}}

**Processing Plan:**
- Generate story context: {{skip_context_generation == false ? 'YES (parallel execution)' : 'NO (skip)'}}
- Validate context: {{validate_context ? 'YES' : 'NO (omitted for speed)'}}
- Mark stories ready: YES (all stories)
    </output>
  </step>

  <step n="3" goal="Generate story context files in parallel" tag="parallel-context-generation">
    <check if="{{skip_context_generation}} == true">
      <output>⏭️  **Skipping context generation** (skip_context_generation=true)
Assuming context files already exist for all stories.
      </output>
      <goto>step 4</goto>
    </check>

    <output>
═══════════════════════════════════════════════════════════
🚀 **Launching Parallel Context Generation**
═══════════════════════════════════════════════════════════

**Strategy:** Launch {{drafted_stories.length}} sub-agents in parallel
**Sub-Agent Type:** Scrum Master (Story Context Specialist)
**Workflow:** story-context
    </output>

    <!-- CRITICAL: Launch ALL sub-agents in a SINGLE parallel invocation -->
    <action>Initialize {{context_results}} array to store results</action>
    <action>Initialize {{failed_stories}} array to track failures</action>

    <critical>You MUST launch ALL story-context sub-agents in PARALLEL using a SINGLE message with multiple tool calls</critical>
    <critical>DO NOT launch sub-agents sequentially - this defeats the purpose of parallelization</critical>

    <action>FOR EACH story in {{drafted_stories}}, prepare parallel sub-agent launch:
      - Agent Type: Scrum Master (Story Context Specialist)
      - Workflow: {{sub_workflows.story_context}}/workflow.yaml
      - Parameter: story_path={{story.file_path}}
      - Expected Output: {{story.context_file_path}}
      - Instruction: "Think hard about this story's context. Consider all relevant documentation, existing code patterns, architectural decisions, and potential integration points. Be thorough in gathering context - the developer will rely on this for implementation."
    </action>

    <action>Launch ALL prepared sub-agents in PARALLEL (single message, multiple tool invocations)</action>
    <action>Wait for ALL sub-agents to complete</action>
    <action>Collect results into {{context_results}} array</action>

    <!-- Process results -->
    <action>For each result in {{context_results}}:
      - If status == 'success': context file created successfully
      - If status == 'error' or 'halt': add to {{failed_stories}} with error message
    </action>

    <check if="{{failed_stories.length}} > 0">
      <output>⚠️ **CONTEXT GENERATION FAILURES**

**Failed Stories:** {{failed_stories.length}} of {{drafted_stories.length}}

{{for each failed_story in failed_stories}}
❌ **{{failed_story.story_key}}**
   Error: {{failed_story.error_message}}
{{end}}

**Recommended Actions:**
1. Review error messages above
2. Fix issues manually (missing docs, unclear story, etc.)
3. Re-run `make-epic-ready` for epic {{epic_key}} to retry

**Successful Stories:** {{drafted_stories.length - failed_stories.length}}
These will be marked ready-for-dev in the next step.
      </output>
      <action>HALT</action>
    </check>

    <output>✅ **All context files generated successfully**

{{for each story in drafted_stories}}
✓ {{story.story_key}} → {{story.context_file_path}}
{{end}}
    </output>
  </step>

  <step n="4" goal="Optional: Validate generated context files" tag="context-validation">
    <check if="{{validate_context}} == false">
      <output>⏭️  **Skipping context validation** (validate_context=false)
Proceeding directly to marking stories ready.
      </output>
      <goto>step 5</goto>
    </check>

    <output>
🔍 **Validating Context Files**

Checking each context file for:
- File exists and is readable
- Valid XML structure
- Contains required sections (acceptance_criteria, story_tasks, etc.)
    </output>

    <action>Initialize {{validation_failures}} array</action>

    <action>For each story in {{drafted_stories}}:
      - Check if {{story.context_file_path}} exists
      - If missing: add to {{validation_failures}} with error "Context file not found"
      - If exists:
        - Read file and verify valid XML structure
        - Check for required elements: acceptance_criteria, story_tasks, technical_context
        - If validation fails: add to {{validation_failures}} with specific error
    </action>

    <check if="{{validation_failures.length}} > 0">
      <output>⚠️ **CONTEXT VALIDATION FAILURES**

**Failed Validations:** {{validation_failures.length}} of {{drafted_stories.length}}

{{for each failure in validation_failures}}
❌ **{{failure.story_key}}**
   Issue: {{failure.error_message}}
   File: {{failure.context_file_path}}
{{end}}

**Recommended Actions:**
1. Review context files manually
2. Re-run `story-context` for specific stories if needed
3. Fix validation issues and re-run `make-epic-ready`
      </output>
      <action>HALT</action>
    </check>

    <output>✅ **All context files validated successfully**</output>
  </step>

  <step n="5" goal="Mark all stories as ready-for-dev" tag="mark-stories-ready">
    <output>
═══════════════════════════════════════════════════════════
📋 **Marking Stories Ready for Development**
═══════════════════════════════════════════════════════════

**Stories to Update:** {{drafted_stories.length}}
**Status Change:** drafted → ready-for-dev
    </output>

    <action>Load {{sprint_status_file}} into memory</action>
    <action>Parse development_status section</action>

    <!-- Update each story status -->
    <action>For each story in {{drafted_stories}}:
      - Find story_key in development_status section
      - Change status from "drafted" to "ready-for-dev"
      - Preserve file order and formatting
    </action>

    <action>Write updated sprint-status.yaml back to {{sprint_status_file}}</action>

    <output>✅ **Sprint status updated**

{{for each story in drafted_stories}}
✓ {{story.story_key}}: drafted → ready-for-dev
{{end}}
    </output>
  </step>

  <step n="6" goal="Epic readiness summary" tag="completion">
    <output>
═══════════════════════════════════════════════════════════
🎉 **EPIC {{epic_key}} STORIES ARE READY!** 🎉
═══════════════════════════════════════════════════════════

**Stories Prepared:** {{drafted_stories.length}}
**Context Files Generated:** {{skip_context_generation ? 'N/A (skipped)' : drafted_stories.length}}
**Stories Marked Ready:** {{drafted_stories.length}}

**Story Summary:**
{{for each story in drafted_stories}}
✅ {{story.story_key}}
   📄 Story: {{story.file_path}}
   📋 Context: {{story.context_file_path}}
   🚦 Status: ready-for-dev
{{end}}

**Next Steps:**
1. Stories are now ready for development
2. Run `finish-epic` epic_key={{epic_key}} to process all stories automatically
3. Or manually run `dev-story` for individual story control

**Start Development:**
Run: `finish-epic` epic_key={{epic_key}}

═══════════════════════════════════════════════════════════
    </output>
  </step>

</workflow>
```

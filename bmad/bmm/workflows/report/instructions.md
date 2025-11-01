# Product Status Report - Workflow Instructions

```xml
<critical>The workflow execution engine is governed by: {project-root}/bmad/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {installed_path}/workflow.yaml</critical>
<critical>Generate all documents in {document_output_language}</critical>
<critical>This workflow generates a product status report showing all epics and their stories.</critical>

<workflow>

  <step n="1" goal="Load configuration and source files">
    <action>Resolve variables from config_source: output_folder, user_name, communication_language</action>
    <action>Load sprint-status.yaml from {{sprint_status_file}}</action>
    <action>Parse the complete development_status section</action>
    <action>Load epics.md from {{epics_file}} if available (for epic descriptions)</action>
  </step>

  <step n="2" goal="Parse epics and calculate metrics">
    <action>Iterate through development_status and identify all epic keys (pattern: epic-N)</action>
    <action>For each epic, collect all associated stories (keys between this epic and next epic/retro)</action>
    <action>Exclude retrospective entries from story counts (pattern: epic-N-retrospective)</action>
    <action>Calculate per-epic metrics:
      - Total stories for this epic
      - Stories by status (backlog, drafted, ready-for-dev, in-progress, review, done)
      - done_count and completion percentage: (done / total) * 100
      - Epic status from epic-N key value (contexted or backlog)
    </action>
    <action>Generate per-epic progress bar (10 chars using █ and ░):
      - filled = round((done_count / total_stories) * 10)
    </action>
    <action>Format epic table with columns: Story | Status | Icon</action>
    <action>Map status to icons: done → ✓, review → 🔍, in-progress → →, ready-for-dev → ⚠, drafted → ○, backlog → ⋯</action>
  </step>

  <step n="3" goal="Calculate overall product metrics">
    <action>Count total epics across entire product</action>
    <action>Count total stories across all epics (exclude retrospectives)</action>
    <action>Count completed epics (all stories done)</action>
    <action>Calculate story status distribution:
      - done_count, review_count, in_progress_count
      - ready_count, drafted_count, backlog_count
      - Calculate percentage for each: (count / total_stories) * 100
    </action>
    <action>Calculate completion percentages:
      - epic_completion_pct = (completed_epics / total_epics) * 100
      - story_completion_pct = (done_count / total_stories) * 100
    </action>
    <action>Generate progress bars (15 chars using █ and ░):
      - epic_completion_bar: filled = round(epic_completion_pct * 15 / 100)
      - story_completion_bar: filled = round(story_completion_pct * 15 / 100)
    </action>
  </step>

  <step n="4" goal="Generate report sections">
    <action>Generate simple progress bars using █ and ░ characters (15 chars total)</action>
    <action>Format epic completion bar: filled chars = (completed_epics / total_epics) * 15</action>
    <action>Format story completion bar: filled chars = (done_stories / total_stories) * 15</action>
    <template-output file="{default_output_file}">project_summary_table</template-output>
    <template-output file="{default_output_file}">epic_status_tables</template-output>
  </step>

  <step n="5" goal="Save and report completion">
    <action>Save document to {{default_output_file}}</action>
    <action>Report file location to {{user_name}}</action>
    <output>**✅ Product Status Report Generated Successfully!**

**Report Details:**
- File: {{default_output_file}}
- Total Epics: {{epic_count}}
- Total Stories: {{story_count}}
- Overall Completion: {{completion_percentage}}%

**Quick Summary:**
- ✓ Completed: {{completed_count}} stories
- ⚡ Active: {{active_count}} stories (in-progress + review)
- → Ready: {{ready_count}} stories
- ⋯ Backlog: {{backlog_count}} stories

Review the report for detailed epic-by-epic breakdown.
    </output>
  </step>

</workflow>
```

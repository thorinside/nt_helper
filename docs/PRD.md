# nt_helper Product Requirements Document (PRD)

**Author:** Neal
**Date:** 2025-10-24
**Project Level:** 2
**Target Scale:** TBD

---

## Goals and Background Context

### Goals

- Default runtime behavior keeps the app silent unless a developer opts in.
- Developers can selectively enable logging by passing tag-based flags at launch.
- Logging output stays focused on actionable diagnostics to streamline debugging.

### Background Context

- Current debug logging produces high-volume noise that obscures new feature diagnostics.
- Logs were generated primarily by LLM-driven development practices and are rarely referenced now.
- Current behavior prevents developers from trusting logs for day-to-day debugging tasks.
- No known platform, compliance, or tooling constraints limit refactoring the logging approach.

---

## Requirements

### Functional Requirements

- Provide CLI flag `--log=<tag-list>` that accepts comma-separated tags (e.g., `--log=network,db`).
- Silence all optional logging when no `--log` flag is provided.
- Route logging calls through a tag-aware logging utility that only emits messages for enabled tags.
- Tag defaults must align with functional groupings (e.g., `network`, `midi`, `db`, `ui`).
- Ensure logging calls fail gracefully when unknown tags are requested (warn once, then ignore).
- Allow multiple functional areas to declare their own tag constants to avoid typos.

### Non-Functional Requirements

- Disabled logging must add negligible runtime overhead (<1% CPU/memory impact in debug builds).
- CLI help output documents the `--log` syntax and available tags.
- Logging configuration honors Flutter desktop, mobile, and CLI execution environments consistently.
- Provide automated coverage (unit or integration) guaranteeing silent mode emits no optional logs.
- New tags can be added by feature teams without editing core logging infrastructure.

---

## User Journeys

- Default experience for musicians using nt_helper remains unchanged; logging is silent for routine synthesis tasks.
- Developers enabling targeted tags receive concise diagnostics aligned to their current feature work.

---

## UX Design Principles

- Prioritize signal over noise—only show logs that unblock active debugging tasks.
- Preserve performer confidence by keeping production and demo sessions free from unexpected console chatter.
- Offer discoverable controls so developers can quickly opt into the diagnostics they need.

---

## User Interface Design Goals

- Surface available logging tags through CLI help output and developer documentation.
- Provide structured log formatting (tag prefix + message) for quick visual scanning when enabled.
- Keep in-app UI unchanged; all configuration handled via launch flags or developer settings.

---

## Epic List

- **Epic 1: Logging Silence and Tag Controls** — Make logging opt-in by default and provide tag-based filtering (est. 4-6 stories).

> **Note:** Detailed epic breakdown with full story specifications is available in [epics.md](./epics.md)

---

## Out of Scope

- Building a runtime GUI for toggling logs after launch.
- Introducing remote telemetry pipelines or centralized log aggregation services.
- Rewriting third-party library logging behavior beyond applying tag filters.


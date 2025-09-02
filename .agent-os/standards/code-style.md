# Code Style Guide

## Context

Global code style rules for Agent OS projects focused on Rust and Flutter applications.

<conditional-block context-check="general-formatting">
IF this General Formatting section already read in current context:
  SKIP: Re-reading this section
  NOTE: "Using General Formatting rules already in context"
ELSE:
  READ: The following formatting rules

## General Formatting

### Indentation
- **Rust**: Use 4 spaces for indentation (rustfmt default)
- **Dart/Flutter**: Use 2 spaces for indentation
- Maintain consistent indentation throughout files
- Align nested structures for readability

### Naming Conventions

#### Rust
- **Functions and Variables**: Use snake_case (e.g., `user_profile`, `calculate_total`)
- **Types, Structs, Enums**: Use PascalCase (e.g., `UserProfile`, `PaymentProcessor`)
- **Constants**: Use UPPER_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`)
- **Modules**: Use snake_case (e.g., `user_management`)
- **Traits**: Use PascalCase, often ending in -able (e.g., `Drawable`, `Serializable`)

#### Dart/Flutter
- **Functions and Variables**: Use camelCase (e.g., `userProfile`, `calculateTotal`)
- **Classes and Widgets**: Use PascalCase (e.g., `UserProfile`, `PaymentWidget`)
- **Constants**: Use lowerCamelCase (e.g., `maxRetryCount`)
- **Files**: Use snake_case (e.g., `user_profile_widget.dart`)

### String Formatting
#### Rust
- Use double quotes for strings: `"Hello World"`
- Use raw strings for regex patterns: `r"[0-9]+"`
- Use format macros: `format!("User {}", name)`

#### Dart/Flutter
- Use single quotes for strings: `'Hello World'`
- Use double quotes when string contains single quotes
- Use string interpolation: `'User $name'` or `'Total: ${calculateTotal()}'`

### Code Comments
- Add brief comments above non-obvious business logic
- Document complex algorithms or calculations
- Explain the "why" behind implementation choices, not the "what"
- Remove outdated comments immediately when code changes
- Delete historical comments, TODO items, and dead code during refactoring
- Keep comments concise and relevant to current implementation
- Use `///` for Rust doc comments and `///` for Dart doc comments
- Prefer self-documenting code over explanatory comments when possible
</conditional-block>

<conditional-block task-condition="rust" context-check="rust-style">
IF current task involves writing or updating Rust code:
  IF rust-style.md already in context:
    SKIP: Re-reading this file
    NOTE: "Using Rust style guide already in context"
  ELSE:
    <context_fetcher_strategy>
      IF current agent is Claude Code AND context-fetcher agent exists:
        USE: @agent:context-fetcher
        REQUEST: "Get Rust formatting rules from code-style/rust-style.md"
        PROCESS: Returned style rules
      ELSE:
        READ the following style guides (only if not already in context):
        - @/Users/nealsanche/.agent-os/standards/code-style/rust-style.md (if not in context)
    </context_fetcher_strategy>
ELSE:
  SKIP: Rust style guide not relevant to current task
</conditional-block>

<conditional-block task-condition="flutter" context-check="flutter-style">
IF current task involves writing or updating Flutter/Dart code:
  IF flutter-style.md already in context:
    SKIP: Re-reading this file
    NOTE: "Using Flutter style guide already in context"
  ELSE:
    <context_fetcher_strategy>
      IF current agent is Claude Code AND context-fetcher agent exists:
        USE: @agent:context-fetcher
        REQUEST: "Get Flutter formatting rules from code-style/flutter-style.md"
        PROCESS: Returned style rules
      ELSE:
        READ the following style guides (only if not already in context):
        - @/Users/nealsanche/.agent-os/standards/code-style/flutter-style.md (if not in context)
    </context_fetcher_strategy>
ELSE:
  SKIP: Flutter style guide not relevant to current task
</conditional-block>

# Development Best Practices

## Context

Global development guidelines for Agent OS projects focused on Rust and Flutter applications.

<conditional-block context-check="core-principles">
IF this Core Principles section already read in current context:
  SKIP: Re-reading this section
  NOTE: "Using Core Principles already in context"
ELSE:
  READ: The following principles

## Core Principles

### Keep It Simple
- Implement code in the fewest lines possible
- Avoid over-engineering solutions
- Choose straightforward approaches over clever ones
- Prefer composition over inheritance (especially in Flutter)

### Optimize for Readability
- Prioritize code clarity over micro-optimizations
- Write self-documenting code with clear variable names
- Add comments for "why" not "what"
- Use Rust's type system to make invalid states unrepresentable

### DRY (Don't Repeat Yourself)
- Extract repeated business logic to functions/methods
- Create reusable Flutter widgets for common UI patterns
- Use Rust macros sparingly and only when they improve clarity
- Create utility functions for common operations

### File Structure
- Keep files focused on a single responsibility
- Group related functionality together
- Use consistent naming conventions
- Follow Rust module conventions and Flutter package structure
</conditional-block>

## Rust-Specific Practices

### Memory Safety & Performance
- Leverage Rust's ownership system to prevent memory issues
- Use `&str` over `String` when possible for parameters
- Prefer `Vec<T>` over `LinkedList<T>` for most collections
- Use `Result<T, E>` for error handling, avoid panicking

### Code Organization
- Structure projects with `lib.rs` for library code and `main.rs` for binaries
- Use modules to organize related functionality
- Keep functions small and focused on single responsibilities
- Use `pub(crate)` for internal APIs

### Testing
- Write unit tests in the same file using `#[cfg(test)]`
- Use integration tests in the `tests/` directory
- Leverage property-based testing with `proptest` for complex logic
- Use `#[should_panic]` sparingly and prefer `Result` assertions

## Flutter-Specific Practices

### Architecture & Separation of Concerns
- **Object-Oriented Design**: Structure code with clear class hierarchies and interfaces
- **Strong Separation**: Maintain strict boundaries between business logic, state, and views
- **No Business Logic in Views**: Views should only handle presentation and user interaction
- **Data-Driven Views**: Build views to be driven by external state, not internal logic
- **Testable in Isolation**: Design views to be independently testable without dependencies
- **Verifiable Correctness**: Ensure views produce predictable outputs for given inputs

### Widget Design
- Create stateless widgets whenever possible
- Use `const` constructors for widgets that don't change
- Break complex widgets into smaller, reusable components
- Follow the single responsibility principle for widgets
- Design widgets as pure functions of their input parameters
- Avoid direct service calls or business logic within widget build methods

### File Size & Organization
- **No Large Files**: Keep widget files small and focused (~100-150 lines maximum)
- **Component Extraction**: Break down large widgets into smaller, focused components in separate files
- **Modular Structure**: Create reusable components that can be imported across the application
- **Composition Pattern**: Build complex UIs by composing smaller, well-tested widgets
- **Single Purpose**: Each widget file should serve one clear, specific purpose

### Refactoring & Code Cleanup
- **Delete Over Rename**: When refactoring, prefer deleting unused files over renaming or keeping them
- **No Historical Comments**: Remove outdated comments, TODO items, and historical notes during refactoring
- **Clean Slate Approach**: Remove commented-out code blocks rather than leaving them for reference
- **Clarifying Comments Only**: Keep only comments that explain complex business logic or non-obvious implementation details
- **Fresh Documentation**: Update documentation to reflect current state, not historical decisions

### State Management
- Use BLoC pattern for complex state management and Cubit for simpler state
- Keep ALL business logic in BLoCs/Cubits, never in widgets or UI components
- Use Freezed for immutable data classes and union types
- Implement proper error handling in async operations with sealed classes
- State should be the single source of truth for UI rendering
- Views should reactively rebuild based on state changes only

### Performance
- Use `ListView.builder` for large lists
- Implement lazy loading for data-heavy screens
- Optimize image loading and caching
- Profile regularly using Flutter DevTools

<conditional-block context-check="dependencies" task-condition="choosing-external-library">
IF current task involves choosing an external library:
  IF Dependencies section already read in current context:
    SKIP: Re-reading this section
    NOTE: "Using Dependencies guidelines already in context"
  ELSE:
    READ: The following guidelines
ELSE:
  SKIP: Dependencies section not relevant to current task

## Dependencies

### Rust Crates
When adding Rust dependencies:
- Check crates.io for download counts and recent updates
- Review the crate's documentation and examples
- Prefer crates that follow semver strictly
- Consider compile-time impact of dependencies
- Use `cargo audit` to check for security vulnerabilities

### Flutter Packages
When adding Flutter packages:
- Check pub.dev popularity and pub points
- Ensure compatibility with target Flutter version
- Review package documentation and examples
- Consider platform support (iOS, Android, Web, Desktop)
- Check for null safety compliance
</conditional-block>

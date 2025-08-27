# Spec Tasks

## Tasks

- [ ] 1. Remove Node Routing Cubit State Management
  - [ ] 1.1 Write tests to verify cubit removal doesn't break app initialization
  - [ ] 1.2 Remove NodeRoutingCubit class from lib/cubit/node_routing_cubit.dart
  - [ ] 1.3 Remove NodeRoutingState class from lib/cubit/node_routing_state.dart
  - [ ] 1.4 Remove any cubit registrations from dependency injection
  - [ ] 1.5 Update imports throughout codebase to remove cubit references
  - [ ] 1.6 Remove test/cubit/node_routing_cubit_test.dart test file
  - [ ] 1.7 Verify all tests pass and app builds without errors

- [ ] 2. Replace Main Routing Canvas with Placeholder Widget
  - [ ] 2.1 Write tests for placeholder widget display and navigation
  - [ ] 2.2 Create simple placeholder widget to replace NodeRoutingWidget
  - [ ] 2.3 Update synchronized_screen.dart to use placeholder instead of NodeRoutingWidget
  - [ ] 2.4 Ensure placeholder maintains proper layout and navigation structure
  - [ ] 2.5 Remove NodeRoutingWidget import from synchronized_screen.dart
  - [ ] 2.6 Verify UI tests pass with new placeholder widget

- [ ] 3. Remove Routing Canvas UI Components
  - [ ] 3.1 Write tests to verify UI component removal doesn't affect other screens
  - [ ] 3.2 Remove NodeRoutingWidget class from lib/ui/routing/node_routing_widget.dart
  - [ ] 3.3 Remove algorithm node widgets (algorithm_node_widget.dart)
  - [ ] 3.4 Remove connection painter widgets (connection_painter.dart, connection_widget.dart)
  - [ ] 3.5 Remove physical node widgets (physical_node_widget.dart)
  - [ ] 3.6 Remove canvas layout widgets (routing_canvas_widget.dart)
  - [ ] 3.7 Remove any remaining routing UI utilities and helpers
  - [ ] 3.8 Verify all UI tests pass after component removal

- [ ] 4. Clean Up Routing Directory Structure
  - [ ] 4.1 Write tests to verify routing analysis functionality still works
  - [ ] 4.2 Preserve routing_page.dart and routing analysis components
  - [ ] 4.3 Remove entire lib/ui/routing/ directory except preserved files
  - [ ] 4.4 Move preserved routing analysis files to appropriate location if needed
  - [ ] 4.5 Update import paths for any preserved routing functionality
  - [ ] 4.6 Remove routing-related test files from test/ui/ directory
  - [ ] 4.7 Remove test/ui/tidy_action_test.dart and other routing canvas tests
  - [ ] 4.8 Verify preserved routing analysis functionality still works

- [ ] 5. Final Cleanup and Verification
  - [ ] 5.1 Write comprehensive integration tests for cleaned codebase
  - [ ] 5.2 Run flutter analyze to ensure zero errors
  - [ ] 5.3 Search codebase for any remaining references to removed components
  - [ ] 5.4 Update pubspec.yaml to remove unused dependencies if any
  - [ ] 5.5 Run all tests to ensure no regressions introduced
  - [ ] 5.6 Test app functionality in demo, offline, and connected modes
  - [ ] 5.7 Verify app builds and runs successfully on target platforms
  - [ ] 5.8 Document any breaking changes or migration notes if needed
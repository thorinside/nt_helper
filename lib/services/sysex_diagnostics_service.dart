import 'dart:async';
import 'dart:math';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/ui/parameter_editor_registry.dart';

class DeviceContext {
  final int totalAlgorithms;
  final int algorithmsInPreset;
  final int? firstAlgorithmParams;

  DeviceContext({
    required this.totalAlgorithms,
    required this.algorithmsInPreset,
    this.firstAlgorithmParams,
  });
}

class SysExDiagnosticsService {
  final IDistingMidiManager _distingManager;

  SysExDiagnosticsService(this._distingManager);

  /// Test a specific range of algorithm library indices to identify problematic algorithms
  Future<DiagnosticsReport> testAlgorithmRange({
    required int startIndex,
    required int endIndex,
    Function(double progress, String currentTest)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final report = DiagnosticsReport();

    // Wake the device first
    await _distingManager.requestWake();
    await Future.delayed(const Duration(milliseconds: 200));

    if (isCancelled?.call() == true) return report;

    final totalTests = endIndex - startIndex + 1;
    int testsCompleted = 0;

    for (
      int algorithmIndex = startIndex;
      algorithmIndex <= endIndex;
      algorithmIndex++
    ) {
      if (isCancelled?.call() == true) break;

      final testName = "Algorithm Info at Library Index $algorithmIndex";
      onProgress?.call(testsCompleted / totalTests, testName);

      final test = DiagnosticTest(
        name: testName,
        category: "Algorithm Library Scan",
        execute: (manager) => manager.requestAlgorithmInfo(algorithmIndex),
      );

      // Run just once for quick scan, or multiple times for detailed testing
      final testResult = await _runSingleTest(test, 1);
      report.addTest(testResult);

      testsCompleted++;

      // Small delay between tests
      await Future.delayed(const Duration(milliseconds: 50));
    }

    onProgress?.call(1.0, "Complete");
    return report;
  }

  /// Runs comprehensive diagnostics on all read-only SysEx commands
  Future<DiagnosticsReport> runFullDiagnostics({
    int repetitions = 5,
    Function(double progress, String currentTest)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final report = DiagnosticsReport();

    // First, wake the device and gather context
    await _distingManager.requestWake();
    await Future.delayed(const Duration(milliseconds: 200));

    if (isCancelled?.call() == true) return report;

    // Get device context to determine which tests are valid
    final context = await _gatherDeviceContext();
    final tests = await _getContextualDiagnosticTests(context);

    for (int i = 0; i < tests.length; i++) {
      if (isCancelled?.call() == true) break;

      final test = tests[i];
      onProgress?.call(i / tests.length, test.name);

      final testResult = await _runSingleTest(test, repetitions);
      report.addTest(testResult);

      // Small delay between tests to avoid overwhelming the device
      await Future.delayed(const Duration(milliseconds: 100));
    }

    onProgress?.call(1.0, "Complete");
    return report;
  }

  /// Gather device context to determine valid test parameters
  Future<DeviceContext> _gatherDeviceContext() async {
    try {
      final numAlgorithms =
          await _distingManager.requestNumberOfAlgorithms() ?? 0;
      final numInPreset =
          await _distingManager.requestNumAlgorithmsInPreset() ?? 0;

      // Get info about first algorithm in preset if available
      int? firstAlgorithmParams;
      if (numInPreset > 0) {
        final paramInfo = await _distingManager.requestNumberOfParameters(0);
        firstAlgorithmParams = paramInfo?.numParameters ?? 0;
      }

      return DeviceContext(
        totalAlgorithms: numAlgorithms,
        algorithmsInPreset: numInPreset,
        firstAlgorithmParams: firstAlgorithmParams,
      );
    } catch (e) {
      // If context gathering fails, use minimal context
      return DeviceContext(
        totalAlgorithms: 0,
        algorithmsInPreset: 0,
        firstAlgorithmParams: null,
      );
    }
  }

  /// Find a parameter with string-type units for string testing
  Future<int?> _findParameterWithStringSupport(
    int slotIndex,
    int maxParams,
  ) async {
    for (int paramIndex = 0; paramIndex < maxParams; paramIndex++) {
      try {
        final paramInfo = await _distingManager.requestParameterInfo(
          slotIndex,
          paramIndex,
        );
        if (paramInfo != null &&
            ParameterEditorRegistry.isStringTypeUnit(paramInfo.unit)) {
          return paramIndex;
        }
      } catch (e) {
        // Skip this parameter if we can't get info
        continue;
      }
    }
    return null;
  }

  /// Runs a specific diagnostic test multiple times
  Future<DiagnosticTestResult> _runSingleTest(
    DiagnosticTest test,
    int repetitions,
  ) async {
    final result = DiagnosticTestResult(test.name, test.category);

    for (int i = 0; i < repetitions; i++) {
      final stopwatch = Stopwatch()..start();
      bool success = false;
      String? error;

      try {
        final response = await test.execute(_distingManager);
        success = response != null;
        if (!success) error = "Null response";
      } catch (e) {
        error = e.toString();
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      result.addExecution(
        DiagnosticExecution(duration: duration, success: success, error: error),
      );

      // Brief delay between repetitions
      await Future.delayed(const Duration(milliseconds: 50));
    }

    return result;
  }

  /// Gets contextual diagnostic tests based on current device state
  Future<List<DiagnosticTest>> _getContextualDiagnosticTests(
    DeviceContext context,
  ) async {
    final tests = <DiagnosticTest>[];

    // Basic device info - always available
    tests.addAll([
      DiagnosticTest(
        name: "Request Version String",
        category: "Device Info",
        execute: (manager) => manager.requestVersionString(),
      ),
      DiagnosticTest(
        name: "Request Unit Strings",
        category: "Device Info",
        execute: (manager) => manager.requestUnitStrings(),
      ),
      DiagnosticTest(
        name: "Request CPU Usage",
        category: "Device Info",
        execute: (manager) => manager.requestCpuUsage(),
      ),
      DiagnosticTest(
        name: "Request Number of Algorithms",
        category: "Algorithm Info",
        execute: (manager) => manager.requestNumberOfAlgorithms(),
      ),
      DiagnosticTest(
        name: "Request Preset Name",
        category: "Preset Info",
        execute: (manager) => manager.requestPresetName(),
      ),
      DiagnosticTest(
        name: "Request Num Algorithms in Preset",
        category: "Preset Info",
        execute: (manager) => manager.requestNumAlgorithmsInPreset(),
      ),
    ]);

    // Test algorithm library queries - test a sample of algorithms from the main library
    // This helps identify if specific algorithms in the library are corrupted
    if (context.totalAlgorithms > 0) {
      // Test first algorithm
      tests.add(
        DiagnosticTest(
          name: "Request Algorithm Info (Library Index 0)",
          category: "Algorithm Library",
          execute: (manager) => manager.requestAlgorithmInfo(0),
        ),
      );

      // Test algorithm at index 12 specifically (the one that was timing out)
      if (context.totalAlgorithms > 12) {
        tests.add(
          DiagnosticTest(
            name: "Request Algorithm Info (Library Index 12)",
            category: "Algorithm Library",
            execute: (manager) => manager.requestAlgorithmInfo(12),
          ),
        );
      }

      // Test a few more algorithms spread throughout the library
      final indicesToTest = <int>[];
      if (context.totalAlgorithms > 50) indicesToTest.add(50);
      if (context.totalAlgorithms > 100) indicesToTest.add(100);
      if (context.totalAlgorithms > 200) indicesToTest.add(200);

      for (final index in indicesToTest) {
        tests.add(
          DiagnosticTest(
            name: "Request Algorithm Info (Library Index $index)",
            category: "Algorithm Library",
            execute: (manager) => manager.requestAlgorithmInfo(index),
          ),
        );
      }

      // Test the last algorithm
      if (context.totalAlgorithms > 1) {
        tests.add(
          DiagnosticTest(
            name:
                "Request Algorithm Info (Library Index ${context.totalAlgorithms - 1})",
            category: "Algorithm Library",
            execute: (manager) =>
                manager.requestAlgorithmInfo(context.totalAlgorithms - 1),
          ),
        );
      }
    }

    // Algorithm-specific tests - only if algorithms exist in preset
    if (context.algorithmsInPreset > 0) {
      tests.addAll([
        DiagnosticTest(
          name: "Request Algorithm Info (Slot 0)",
          category: "Algorithm Info",
          execute: (manager) => manager.requestAlgorithmInfo(0),
        ),
        DiagnosticTest(
          name: "Request Algorithm GUID (Slot 0)",
          category: "Algorithm Info",
          execute: (manager) => manager.requestAlgorithmGuid(0),
        ),
        DiagnosticTest(
          name: "Request Number of Parameters (Slot 0)",
          category: "Parameters",
          execute: (manager) => manager.requestNumberOfParameters(0),
        ),
        DiagnosticTest(
          name: "Request Parameter Pages (Slot 0)",
          category: "Parameters",
          execute: (manager) => manager.requestParameterPages(0),
        ),
        DiagnosticTest(
          name: "Request All Parameter Values (Slot 0)",
          category: "Parameters",
          execute: (manager) => manager.requestAllParameterValues(0),
        ),
        DiagnosticTest(
          name: "Request Routing Information (Slot 0)",
          category: "Routing",
          execute: (manager) => manager.requestRoutingInformation(0),
        ),
      ]);

      // Parameter-specific tests - only if the first algorithm has parameters
      if (context.firstAlgorithmParams != null &&
          context.firstAlgorithmParams! > 0) {
        tests.addAll([
          DiagnosticTest(
            name: "Request Parameter Info (Slot 0, Param 0)",
            category: "Parameters",
            execute: (manager) => manager.requestParameterInfo(0, 0),
          ),
          DiagnosticTest(
            name: "Request Parameter Value (Slot 0, Param 0)",
            category: "Parameters",
            execute: (manager) => manager.requestParameterValue(0, 0),
          ),
          DiagnosticTest(
            name: "Request Mappings (Slot 0, Param 0)",
            category: "Routing",
            execute: (manager) => manager.requestMappings(0, 0),
          ),
        ]);

        // Only test parameter value strings for parameters that support them (string-type units)
        final stringParamIndex = await _findParameterWithStringSupport(
          0,
          context.firstAlgorithmParams!,
        );
        if (stringParamIndex != null) {
          tests.add(
            DiagnosticTest(
              name:
                  "Request Parameter Value String (Slot 0, Param $stringParamIndex)",
              category: "Parameters",
              execute: (manager) =>
                  manager.requestParameterValueString(0, stringParamIndex),
            ),
          );
        }
      }
    }

    return tests;
  }
}

class DiagnosticTest {
  final String name;
  final String category;
  final Future<dynamic> Function(IDistingMidiManager manager) execute;

  DiagnosticTest({
    required this.name,
    required this.category,
    required this.execute,
  });
}

class DiagnosticExecution {
  final int duration; // milliseconds
  final bool success;
  final String? error;

  DiagnosticExecution({
    required this.duration,
    required this.success,
    this.error,
  });
}

class DiagnosticTestResult {
  final String testName;
  final String category;
  final List<DiagnosticExecution> executions = [];

  DiagnosticTestResult(this.testName, this.category);

  void addExecution(DiagnosticExecution execution) {
    executions.add(execution);
  }

  int get totalExecutions => executions.length;
  int get successfulExecutions => executions.where((e) => e.success).length;
  int get failedExecutions => executions.where((e) => !e.success).length;
  double get successRate =>
      totalExecutions > 0 ? successfulExecutions / totalExecutions : 0.0;

  int get minDuration =>
      executions.isEmpty ? 0 : executions.map((e) => e.duration).reduce(min);
  int get maxDuration =>
      executions.isEmpty ? 0 : executions.map((e) => e.duration).reduce(max);
  double get avgDuration => executions.isEmpty
      ? 0.0
      : executions.map((e) => e.duration).reduce((a, b) => a + b) /
            executions.length;

  List<String> get uniqueErrors => executions
      .where((e) => e.error != null)
      .map((e) => e.error!)
      .toSet()
      .toList();
}

class DiagnosticsReport {
  final List<DiagnosticTestResult> testResults = [];
  final DateTime timestamp = DateTime.now();

  void addTest(DiagnosticTestResult result) {
    testResults.add(result);
  }

  int get totalTests => testResults.length;
  int get passedTests => testResults.where((t) => t.successRate > 0.8).length;
  int get failedTests => testResults.where((t) => t.successRate <= 0.8).length;

  List<DiagnosticTestResult> get worstPerformingTests =>
      testResults.where((t) => t.successRate < 1.0).toList()
        ..sort((a, b) => a.successRate.compareTo(b.successRate));

  List<DiagnosticTestResult> get slowestTests =>
      testResults.toList()
        ..sort((a, b) => b.avgDuration.compareTo(a.avgDuration));

  Map<String, List<DiagnosticTestResult>> get testsByCategory {
    final Map<String, List<DiagnosticTestResult>> grouped = {};
    for (final test in testResults) {
      grouped.putIfAbsent(test.category, () => []).add(test);
    }
    return grouped;
  }

  String generateTextReport() {
    final buffer = StringBuffer();
    buffer.writeln('SysEx Diagnostics Report');
    buffer.writeln('Generated: ${timestamp.toIso8601String()}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    buffer.writeln('SUMMARY');
    buffer.writeln('Total Tests: $totalTests');
    buffer.writeln('Passed (>80% success): $passedTests');
    buffer.writeln('Failed (≤80% success): $failedTests');
    buffer.writeln();

    if (worstPerformingTests.isNotEmpty) {
      buffer.writeln('WORST PERFORMING TESTS');
      for (final test in worstPerformingTests.take(5)) {
        buffer.writeln(
          '${test.testName}: ${(test.successRate * 100).toStringAsFixed(1)}% success, '
          '${test.avgDuration.toStringAsFixed(1)}ms avg',
        );
        if (test.uniqueErrors.isNotEmpty) {
          buffer.writeln('  Errors: ${test.uniqueErrors.join(', ')}');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('SLOWEST TESTS');
    for (final test in slowestTests.take(5)) {
      buffer.writeln(
        '${test.testName}: ${test.avgDuration.toStringAsFixed(1)}ms avg '
        '(${test.minDuration}ms min, ${test.maxDuration}ms max)',
      );
    }
    buffer.writeln();

    buffer.writeln('BY CATEGORY');
    for (final entry in testsByCategory.entries) {
      buffer.writeln('${entry.key}:');
      for (final test in entry.value) {
        buffer.writeln(
          '  ${test.testName}: ${(test.successRate * 100).toStringAsFixed(1)}% success, '
          '${test.avgDuration.toStringAsFixed(1)}ms avg',
        );
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}

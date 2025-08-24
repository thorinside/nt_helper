import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/services/sysex_diagnostics_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DebugDiagnosticsScreen extends StatefulWidget {
  final DistingCubit distingCubit;

  const DebugDiagnosticsScreen({
    super.key,
    required this.distingCubit,
  });

  @override
  State<DebugDiagnosticsScreen> createState() => _DebugDiagnosticsScreenState();
}

class _DebugDiagnosticsScreenState extends State<DebugDiagnosticsScreen> {
  SysExDiagnosticsService? _diagnosticsService;
  DiagnosticsReport? _currentReport;
  bool _isRunning = false;
  bool _cancelled = false;
  double _progress = 0.0;
  String _currentTest = "";
  int _repetitions = 5;

  @override
  void initState() {
    super.initState();
    final currentState = widget.distingCubit.state;
    if (currentState is DistingStateSynchronized && !currentState.offline) {
      _diagnosticsService = SysExDiagnosticsService(
        widget.distingCubit.requireDisting()
      );
    }
  }

  Future<void> _runDiagnostics() async {
    if (_diagnosticsService == null) return;
    
    setState(() {
      _isRunning = true;
      _cancelled = false;
      _progress = 0.0;
      _currentTest = "Initializing...";
      _currentReport = null;
    });

    try {
      // Wake device first
      await widget.distingCubit.requireDisting().requestWake();
      await Future.delayed(const Duration(milliseconds: 200));
      
      final report = await _diagnosticsService!.runFullDiagnostics(
        repetitions: _repetitions,
        onProgress: (progress, currentTest) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _currentTest = currentTest;
            });
          }
        },
        isCancelled: () => _cancelled,
      );

      if (mounted && !_cancelled) {
        setState(() {
          _currentReport = report;
          _currentTest = "Complete";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Diagnostics failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  void _cancelDiagnostics() {
    setState(() {
      _cancelled = true;
    });
  }

  Future<void> _exportReport() async {
    if (_currentReport == null) return;

    try {
      final textReport = _currentReport!.generateTextReport();
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Use share on mobile platforms
        await Share.share(
          textReport,
          subject: 'SysEx Diagnostics Report - ${_currentReport!.timestamp}',
        );
      } else {
        // Save to file on desktop platforms
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = _currentReport!.timestamp
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')[0]; // Remove milliseconds and colons
        final file = File('${directory.path}/sysex_diagnostics_$timestamp.txt');
        await file.writeAsString(textReport);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report saved to: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export report: $e')),
        );
      }
    }
  }

  void _copyReportToClipboard() {
    if (_currentReport == null) return;
    
    final textReport = _currentReport!.generateTextReport();
    Clipboard.setData(ClipboardData(text: textReport));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debug Diagnostics')),
        body: const Center(
          child: Text('Debug diagnostics are only available in debug mode.'),
        ),
      );
    }

    final currentState = widget.distingCubit.state;
    final isOffline = currentState is DistingStateSynchronized && currentState.offline;

    if (isOffline || _diagnosticsService == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debug Diagnostics')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Device must be connected to run diagnostics.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Diagnostics'),
        actions: _currentReport != null && !_isRunning
          ? [
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy to Clipboard',
                onPressed: _copyReportToClipboard,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Export Report',
                onPressed: _exportReport,
              ),
            ]
          : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SysEx Command Diagnostics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool tests all read-only SysEx commands to identify timing issues and failures during synchronization.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Repetitions per test: '),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _repetitions,
                          items: [3, 5, 10, 20].map((value) => 
                            DropdownMenuItem(
                              value: value, 
                              child: Text('$value')
                            )
                          ).toList(),
                          onChanged: _isRunning ? null : (value) {
                            if (value != null) {
                              setState(() {
                                _repetitions = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isRunning ? null : _runDiagnostics,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Run Diagnostics'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_isRunning)
                          ElevatedButton.icon(
                            onPressed: _cancelDiagnostics,
                            icon: const Icon(Icons.stop),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    if (_isRunning) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 8),
                      Text('Current: $_currentTest'),
                      Text('Progress: ${(_progress * 100).toStringAsFixed(1)}%'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentReport != null) ...[
              Expanded(
                child: _buildReportView(_currentReport!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportView(DiagnosticsReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostics Report',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Generated: ${report.timestamp.toLocal()}'),
            const SizedBox(height: 16),
            _buildSummarySection(report),
            const SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Issues'),
                        Tab(text: 'Performance'),
                        Tab(text: 'By Category'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildIssuesTab(report),
                          _buildPerformanceTab(report),
                          _buildCategoryTab(report),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(DiagnosticsReport report) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Tests', '${report.totalTests}', Colors.blue),
          _buildSummaryItem('Passed', '${report.passedTests}', Colors.green),
          _buildSummaryItem('Failed', '${report.failedTests}', 
            report.failedTests > 0 ? Colors.red : Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildIssuesTab(DiagnosticsReport report) {
    final problematicTests = report.worstPerformingTests;
    
    if (problematicTests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No issues detected! All tests passed successfully.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: problematicTests.length,
      itemBuilder: (context, index) {
        final test = problematicTests[index];
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.warning,
              color: test.successRate < 0.5 ? Colors.red : Colors.orange,
            ),
            title: Text(test.testName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Success Rate: ${(test.successRate * 100).toStringAsFixed(1)}%'),
                Text('Avg Response: ${test.avgDuration.toStringAsFixed(1)}ms'),
                if (test.uniqueErrors.isNotEmpty)
                  Text('Errors: ${test.uniqueErrors.join(', ')}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceTab(DiagnosticsReport report) {
    final slowestTests = report.slowestTests.take(10).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: slowestTests.length,
      itemBuilder: (context, index) {
        final test = slowestTests[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPerformanceColor(test.avgDuration),
              child: Text('${index + 1}'),
            ),
            title: Text(test.testName),
            subtitle: Text('${test.avgDuration.toStringAsFixed(1)}ms avg '
                          '(${test.minDuration}-${test.maxDuration}ms range)'),
            trailing: Text(
              '${(test.successRate * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: test.successRate == 1.0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTab(DiagnosticsReport report) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: report.testsByCategory.entries.map((entry) {
        return Card(
          child: ExpansionTile(
            title: Text(entry.key),
            subtitle: Text('${entry.value.length} tests'),
            children: entry.value.map((test) {
              return ListTile(
                title: Text(test.testName),
                subtitle: Text('${test.avgDuration.toStringAsFixed(1)}ms avg'),
                trailing: Text(
                  '${(test.successRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: test.successRate == 1.0 ? Colors.green : Colors.red,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Color _getPerformanceColor(double avgDuration) {
    if (avgDuration < 100) return Colors.green;
    if (avgDuration < 500) return Colors.orange;
    return Colors.red;
  }
}
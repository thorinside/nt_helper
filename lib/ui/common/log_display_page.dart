import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:nt_helper/util/in_app_logger.dart';
import 'package:provider/provider.dart';

class LogDisplayPage extends StatelessWidget {
  const LogDisplayPage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const LogDisplayPage());
  }

  @override
  Widget build(BuildContext context) {
    final logger = Provider.of<InAppLogger>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Logs'),
        actions: [
          IconButton(
            icon: Icon(
              logger.isRecording
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
            ),
            tooltip: logger.isRecording ? 'Pause Logging' : 'Resume Logging',
            onPressed: () {
              if (logger.isRecording) {
                logger.stopRecording();
              } else {
                logger.startRecording();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy Logs',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: logger.logs.join('\n')));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear Logs',
            onPressed: () {
              logger.clearLogs();
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: logger.logs.length,
        reverse: true, // Show newest logs first
        itemBuilder: (context, index) {
          // Display logs in reverse order from the list (newest at the bottom of the list, displayed at top)
          final logEntry = logger.logs[logger.logs.length - 1 - index];
          return SelectableText(
            logEntry,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          );
        },
      ),
    );
  }
}

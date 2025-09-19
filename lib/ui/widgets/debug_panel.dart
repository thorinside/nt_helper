import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nt_helper/services/debug_service.dart';

class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  final ScrollController _scrollController = ScrollController();
  final DebugService _debugService = DebugService();

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom when new messages arrive
    _debugService.debugStream.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.bug_report, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'USB Video Debug Log',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear),
                  iconSize: 16,
                  onPressed: () {
                    _debugService.clearMessages();
                    setState(() {});
                  },
                  tooltip: 'Clear log',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 200,
            child: StreamBuilder<String>(
              stream: _debugService.debugStream,
              builder: (context, snapshot) {
                final messages = _debugService.debugMessages;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No debug messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
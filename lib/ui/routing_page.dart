import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/routing_information.dart';

class RoutingPage extends StatefulWidget {
  // Changed to StatefulWidget
  final DistingCubit cubit;

  const RoutingPage({super.key, required this.cubit});

  @override
  State<RoutingPage> createState() => _RoutingPageState();
}

class _RoutingPageState extends State<RoutingPage> {
  bool _loading = true;
  List<RoutingInformation> _routingInformation = [];
  bool _isRealtimeActive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestRoutingRefresh(); // Load initial data
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _requestRoutingRefresh() async {
    try {
      await widget.cubit.refreshRouting();
      setState(() {
        _routingInformation = widget.cubit.buildRoutingInformation();
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        "Failed to access DistingCubit or call fetchCurrentRoutingState: $e",
      );
      // Optionally, handle the error (e.g., stop realtime updates)
      if (mounted) {
        setState(() {
          _isRealtimeActive = false;
          _timer?.cancel();
        });
      }
    }
  }

  void _toggleRealtime() {
    setState(() {
      _isRealtimeActive = !_isRealtimeActive;
      if (_isRealtimeActive) {
        _requestRoutingRefresh(); // Initial fetch upon activation
        _timer
            ?.cancel(); // Ensure any existing timer is stopped before starting a new one
        _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
          if (!_isRealtimeActive) {
            // Check if still active before fetching
            timer.cancel();
            return;
          }
          _requestRoutingRefresh();
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routing Diagnostics'),
        actions: [
          IconButton(
            icon: Icon(
              _isRealtimeActive ? Icons.sync : Icons.sync_disabled,
              color: _isRealtimeActive
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: _isRealtimeActive
                ? 'Stop Realtime Updates'
                : 'Start Realtime Updates',
            onPressed: _toggleRealtime,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Routing Analysis',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    ..._routingInformation.map((routing) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Slot ${routing.algorithmIndex}: ${routing.algorithmName}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text('Routing Info: ${routing.routingInfo.join(", ")}'),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
    );
  }
}

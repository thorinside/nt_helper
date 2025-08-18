import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/node_routing_cubit.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/node_positions_persistence_service.dart';
import 'package:nt_helper/ui/routing/routing_table_widget.dart';
import 'package:nt_helper/ui/routing/node_routing_widget.dart';

enum RoutingViewMode { table, node }

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
  RoutingViewMode _viewMode = RoutingViewMode.table;

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
          "Failed to access DistingCubit or call fetchCurrentRoutingState: $e");
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

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == RoutingViewMode.table 
          ? RoutingViewMode.node 
          : RoutingViewMode.table;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routing Analysis'),
        actions: [
          IconButton(
            icon: Icon(
              _viewMode == RoutingViewMode.table ? Icons.account_tree : Icons.table_chart,
            ),
            tooltip: _viewMode == RoutingViewMode.table 
                ? 'Switch to Node View'
                : 'Switch to Table View',
            onPressed: _toggleViewMode,
          ),
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
          : _viewMode == RoutingViewMode.table
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: RoutingTableWidget(
                      routing: _routingInformation,
                      showSignals: true,
                      showMappings: false,
                    ),
                  ),
                )
              : BlocProvider(
                  create: (context) => NodeRoutingCubit(widget.cubit, AlgorithmMetadataService(), NodePositionsPersistenceService()),
                  child: NodeRoutingWidget(
                    routing: _routingInformation,
                    showSignals: true,
                    showMappings: false,
                  ),
                ),
    );
  }
}

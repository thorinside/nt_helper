// Example usage in a Flutter app:
import 'package:flutter/material.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/ui/routing/routing_table_widget.dart';

class RoutingPage extends StatelessWidget {
  const RoutingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final routing = <RoutingInformation>[
      RoutingInformation(
        algorithmIndex: 0,
        // Suppose the first 3 ints are masks for input, output, replace,
        // and the 6th int is "mapping" used in netInputMask logic
        routingInfo: [0x1000, 0x2000, 0x2000, 0, 0, 0x1000],
        algorithmName: "Algorithm A",
      ),
      RoutingInformation(
        algorithmIndex: 1,
        routingInfo: [0x1800, 0x1400, 0, 0, 0, 0x0100],
        algorithmName: "Algorithm B",
      ),
      // etc.
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Routing Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: RoutingTableWidget(
            routing: routing,
            color1: Colors.yellow,
            color2: Colors.green,
            showSignals: true,
            showMappings: true,
          ),
        ),
      ),
    );
  }
}

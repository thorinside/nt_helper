import 'package:flutter/material.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/ui/routing/routing_table_widget.dart';

class RoutingPage extends StatelessWidget {
  final List<RoutingInformation> routing;

  const RoutingPage({super.key, required this.routing});

  @override
  Widget build(BuildContext context) {
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

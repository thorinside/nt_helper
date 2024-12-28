import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class SynchronizedScreen extends StatelessWidget {
  final List<Slot> slots;
  final List<AlgorithmInfo> algorithms;

  const SynchronizedScreen(
      {Key? key, required this.slots, required this.algorithms})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: slots.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Disting NT Preset Editor'),
          bottom: TabBar(
            isScrollable: true,
            tabs: slots.map((slot) {
              final algorithmName = algorithms
                  .firstWhere(
                      (element) => element.guid == slot.algorithmGuid.guid)
                  .name;
              return Tab(text: algorithmName);
            }).toList(),
          ),
        ),
        body: TabBarView(
          children: slots.map((slot) {
            return SlotDetailView(slot: slot);
          }).toList(),
        ),
      ),
    );
  }
}

class SlotDetailView extends StatelessWidget {
  final Slot slot;

  const SlotDetailView({Key? key, required this.slot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: slot.parameters.length,
      itemBuilder: (context, index) {
        final parameter = slot.parameters.elementAtOrNull(index);
        final value = slot.values.elementAtOrNull(index);
        final enumStrings = slot.enums.elementAtOrNull(index);
        final mapping = slot.mappings.elementAtOrNull(index);
        final valueString = slot.valueStrings.elementAtOrNull(index);

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(parameter!.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Value: ${value?.value}'),
                if (enumStrings?.values.isNotEmpty == true)
                  Text('Enum: ${enumStrings?.values.join(", ")}'),
                Text('Mapping: ${mapping?.packedMappingData.toString()}'),
                if (valueString?.value.isNotEmpty == true)
                  Text('String: ${valueString?.value}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

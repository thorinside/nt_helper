import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/ui/algorithm_registry.dart';
import 'package:nt_helper/ui/widgets/section_parameter_controller.dart';
import 'package:nt_helper/ui/widgets/section_parameter_list_view.dart';

class SlotDetailView extends StatefulWidget {
  final Slot slot;
  final int slotIndex;
  final List<String> units;
  final FirmwareVersion firmwareVersion;
  final SectionParameterController? sectionController;

  const SlotDetailView({
    super.key,
    required this.slot,
    required this.slotIndex,
    required this.units,
    required this.firmwareVersion,
    this.sectionController,
  });

  @override
  State<SlotDetailView> createState() => _SlotDetailViewState();
}

class _SlotDetailViewState extends State<SlotDetailView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Provide a full replacement view
    final view = AlgorithmViewRegistry.findViewFor(
      widget.slot,
      widget.slotIndex,
      widget.firmwareVersion,
    );
    if (view != null) return view;

    // Create a set of list sections for the parameters of the
    // algorithm initially based off Os' organization on the module firmware.

    return SafeArea(
      child: SectionParameterListView(
        slot: widget.slot,
        slotIndex: widget.slotIndex,
        units: widget.units,
        pages: widget.slot.pages,
        sectionController: widget.sectionController,
      ),
    );
  }
}

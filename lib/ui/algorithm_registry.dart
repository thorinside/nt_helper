import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart' show Slot;
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/ui/notes_algorithm_view.dart';

class AlgorithmViewRegistry {
  static Widget? findViewFor(Slot slot, FirmwareVersion firmwareVersion) {
    switch (slot.algorithm.guid) {
      case 'note':
        return NotesAlgorithmView(slot: slot, firmwareVersion: firmwareVersion);
    }
    return null;
  }
}

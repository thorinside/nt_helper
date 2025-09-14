import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

part 'preset_browser_state.freezed.dart';

enum PanelPosition { left, center, right }

enum SortMode { alphabetic, date }

@freezed
class PresetBrowserState with _$PresetBrowserState {
  const factory PresetBrowserState.initial() = _Initial;

  const factory PresetBrowserState.loading() = _Loading;

  const factory PresetBrowserState.loaded({
    required String currentPath,
    required List<DirectoryEntry> leftPanelItems,
    required List<DirectoryEntry> centerPanelItems,
    required List<DirectoryEntry> rightPanelItems,
    DirectoryEntry? selectedLeftItem,
    DirectoryEntry? selectedCenterItem,
    DirectoryEntry? selectedRightItem,
    required List<String> navigationHistory,
    required bool sortByDate,
    Map<String, List<DirectoryEntry>>? directoryCache,
    // Mobile drill-down navigation fields
    String? drillPath,
    List<String>? breadcrumbs,
    List<DirectoryEntry>? currentDrillItems,
    DirectoryEntry? selectedDrillItem,
  }) = _Loaded;

  const factory PresetBrowserState.error({
    required String message,
    String? lastPath,
  }) = _Error;
}

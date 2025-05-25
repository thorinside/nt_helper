import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/ui/sd_card_scanner/sd_card_scanner_page.dart'; // For ScannedCardData

part 'sd_card_scanner_state.freezed.dart';

enum ScanStatus {
  initial,
  validating,
  findingFiles,
  parsing,
  saving,
  complete,
  error,
  cancelled
}

@freezed
class SdCardScannerState with _$SdCardScannerState {
  const factory SdCardScannerState({
    @Default(ScanStatus.initial) ScanStatus status,
    @Default([]) List<ScannedCardData> scannedCards,
    @Default(0.0) double scanProgress,
    @Default(0) int filesProcessed,
    @Default(0) int totalFiles,
    @Default('') String currentFile,
    String? errorMessage,
    String? successMessage,
    ScannedCardData? newlyScannedCard, // To highlight or use after a scan
  }) = _SdCardScannerState;
}

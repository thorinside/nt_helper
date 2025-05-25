import 'package:freezed_annotation/freezed_annotation.dart';

part 'sd_card_scanner_event.freezed.dart';

@freezed
abstract class SdCardScannerEvent with _$SdCardScannerEvent {
  const factory SdCardScannerEvent.loadScannedCards() = LoadScannedCards;
  const factory SdCardScannerEvent.scanRequested({
    required String path,
    required String cardName,
  }) = ScanRequested;
  const factory SdCardScannerEvent.rescanCardRequested({
    required String cardIdPath,
    required String cardName,
  }) = RescanCardRequested;
  const factory SdCardScannerEvent.scanCancelled() = ScanCancelled;
  const factory SdCardScannerEvent.removeCardRequested({
    required String cardIdPath,
  }) = RemoveCardRequested;
  const factory SdCardScannerEvent.clearMessages() = ClearMessages;
}

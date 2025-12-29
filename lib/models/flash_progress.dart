import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/models/flash_stage.dart';

part 'flash_progress.freezed.dart';
part 'flash_progress.g.dart';

@freezed
sealed class FlashProgress with _$FlashProgress {
  const factory FlashProgress({
    required FlashStage stage,
    required int percent,
    required String message,
    @Default(false) bool isError,
  }) = _FlashProgress;

  factory FlashProgress.fromJson(Map<String, dynamic> json) =>
      _$FlashProgressFromJson(json);
}

/// Exception thrown when the flash tool download fails
class FlashToolDownloadException implements Exception {
  final String message;

  const FlashToolDownloadException(this.message);

  @override
  String toString() => 'FlashToolDownloadException: $message';
}

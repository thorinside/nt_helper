/// Operation codes carried inside Disting NT SD-card SysEx messages (`0x7A`).
enum SdCardOperation {
  directoryListing(1),
  fileDownload(2),
  fileDelete(3),
  fileUpload(4),
  fileRename(5),
  remount(6),
  directoryCreate(7),
  rescanPlugins(8);

  const SdCardOperation(this.code);

  final int code;

  static SdCardOperation? fromCode(int code) {
    for (final operation in values) {
      if (operation.code == code) {
        return operation;
      }
    }
    return null;
  }
}

/// A firmware error returned for an SD-card operation.
///
/// SD error frames do not repeat the operation code, so the scheduler supplies
/// the operation from the active request key.
class SdCardOperationException implements Exception {
  const SdCardOperationException({
    required this.operation,
    required this.message,
  });

  factory SdCardOperationException.fromPayload({
    required SdCardOperation operation,
    required List<int> payload,
  }) {
    final terminator = payload.indexOf(0, 1);
    final end = terminator == -1 ? payload.length : terminator;
    final message = end > 1
        ? String.fromCharCodes(payload.sublist(1, end))
        : 'SD card operation failed';

    return SdCardOperationException(operation: operation, message: message);
  }

  final SdCardOperation operation;
  final String message;

  @override
  String toString() => 'SD ${operation.name} failed: $message';
}

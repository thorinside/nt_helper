import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/request_key.dart';
import 'package:nt_helper/domain/sd_card_operation.dart';
import 'package:nt_helper/domain/sysex/sysex_parser.dart';

void main() {
  group('RequestKey SD-card operation matching', () {
    test('successful response must carry the requested operation', () {
      final key = RequestKey(
        sysExId: 0,
        messageType: DistingNTRespMessageType.respDirectoryListing,
        sdCardOperation: SdCardOperation.directoryListing,
      );

      expect(
        key.matches(_sdMessage([0, SdCardOperation.directoryListing.code])),
        isTrue,
      );
      expect(
        key.matches(_sdMessage([0, SdCardOperation.fileUpload.code])),
        isFalse,
      );
      expect(
        key.matchesStrict(_sdMessage([0, SdCardOperation.fileUpload.code])),
        isFalse,
      );
    });

    test('operation-less error matches the active SD request', () {
      final key = RequestKey(
        sysExId: 0,
        messageType: DistingNTRespMessageType.respDirectoryListing,
        sdCardOperation: SdCardOperation.fileUpload,
      );
      final error = _sdMessage([1, 110, 111, 112, 101, 0]);

      expect(key.matches(error), isTrue);
      expect(key.matchesStrict(error), isTrue);
    });

    test('operation participates in key equality and hashing', () {
      final listing = RequestKey(
        sysExId: 0,
        messageType: DistingNTRespMessageType.respDirectoryListing,
        sdCardOperation: SdCardOperation.directoryListing,
      );
      final upload = RequestKey(
        sysExId: 0,
        messageType: DistingNTRespMessageType.respDirectoryListing,
        sdCardOperation: SdCardOperation.fileUpload,
      );

      expect(listing, isNot(upload));
      expect({listing, upload}, hasLength(2));
    });
  });
}

DistingNTParsedMessage _sdMessage(List<int> payload) {
  return DistingNTParsedMessage(
    sysExId: 0,
    messageType: DistingNTRespMessageType.respDirectoryListing,
    payload: Uint8List.fromList(payload),
    rawBytes: Uint8List(0),
  );
}

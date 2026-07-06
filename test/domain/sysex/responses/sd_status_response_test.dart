import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/response_factory.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

void main() {
  group('SD-card operation status responses', () {
    test('parses upload ACK carried by SD-card operation response', () {
      final response = ResponseFactory.fromMessageType(
        DistingNTRespMessageType.respDirectoryListing,
        Uint8List.fromList([0, 4]),
      );

      final status = response!.parse() as SdCardStatus;

      expect(status.success, isTrue);
    });

    test('parses error text carried by SD-card operation response', () {
      final response = ResponseFactory.fromMessageType(
        DistingNTRespMessageType.respDirectoryListing,
        Uint8List.fromList([1, ...ascii.encode('nope'), 0]),
      );

      final status = response!.parse() as SdCardStatus;

      expect(status.success, isFalse);
      expect(status.message, 'nope');
    });
  });
}

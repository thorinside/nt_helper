import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class TruncatedParameterPagesException implements Exception {
  TruncatedParameterPagesException({
    required this.algorithmIndex,
    required this.expectedPages,
    required this.completedPages,
    required this.truncatedPageName,
    required this.offset,
    required this.payloadLength,
  });

  final int algorithmIndex;
  final int expectedPages;
  final int completedPages;
  final String truncatedPageName;
  final int offset;
  final int payloadLength;

  @override
  String toString() {
    return 'TruncatedParameterPagesException('
        'algorithmIndex: $algorithmIndex, '
        'expectedPages: $expectedPages, '
        'completedPages: $completedPages, '
        'truncatedPageName: "$truncatedPageName", '
        'offset: $offset, '
        'payloadLength: $payloadLength'
        ')';
  }
}

class ParameterPagesResponse extends SysexResponse {
  late final ParameterPages parameterPages;
  ParameterPagesResponse(super.data);

  @override
  ParameterPages parse() {
    var algorithmIndex = data[0].toInt();
    var numPages = data[1].toInt();
    int offset = 2;
    final pages = <ParameterPage>[];

    for (var pageIndex = 0; pageIndex < numPages; pageIndex++) {
      if (offset >= data.length) {
        throw TruncatedParameterPagesException(
          algorithmIndex: algorithmIndex,
          expectedPages: numPages,
          completedPages: pages.length,
          truncatedPageName: '<missing page name>',
          offset: offset,
          payloadLength: data.length,
        );
      }

      final strInfo = decodeNullTerminatedAscii(data, offset);
      offset = strInfo.nextOffset;
      final name = strInfo.value;

      if (offset == data.length && data.last != 0) {
        throw TruncatedParameterPagesException(
          algorithmIndex: algorithmIndex,
          expectedPages: numPages,
          completedPages: pages.length,
          truncatedPageName: '<unterminated page name: $name>',
          offset: offset,
          payloadLength: data.length,
        );
      }

      if (offset >= data.length) {
        throw TruncatedParameterPagesException(
          algorithmIndex: algorithmIndex,
          expectedPages: numPages,
          completedPages: pages.length,
          truncatedPageName: name,
          offset: offset,
          payloadLength: data.length,
        );
      }
      final numParameters = data[offset++];
      final parameterNumbers = <int>[];

      for (var i = 0; i < numParameters; i++) {
        if (offset + 1 >= data.length) {
          throw TruncatedParameterPagesException(
            algorithmIndex: algorithmIndex,
            expectedPages: numPages,
            completedPages: pages.length,
            truncatedPageName: name,
            offset: offset,
            payloadLength: data.length,
          );
        }
        parameterNumbers.add(data[offset++] << 7 | data[offset++]);
      }

      pages.add(ParameterPage(name: name, parameters: parameterNumbers));
    }

    return ParameterPages(algorithmIndex: algorithmIndex, pages: pages);
  }
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/chat/utils/pdf_text_extractor.dart';

void main() {
  group('extractPdfText', () {
    test('preserves mixed literal and hex TJ array order', () {
      final text = extractPdfText(
        latin1.encode(_pdfWithContentStream('BT\n[(A)<42>(C)] TJ\nET')),
      );

      expect(text, 'ABC');
    });
  });
}

String _pdfWithContentStream(String stream) =>
    '''
%PDF-1.4
1 0 obj
<< /Type /Page /Contents 2 0 R >>
endobj
2 0 obj
<< /Length ${stream.length} >>
stream
$stream
endstream
endobj
trailer
<< /Root 1 0 R >>
%%EOF
''';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/services/algorithm_guid_utils.dart';

void main() {
  group('AlgorithmGuidUtils', () {
    test('identifies factory GUIDs', () {
      expect(AlgorithmGuidUtils.isFactoryGuid('lfo '), isTrue);
      expect(AlgorithmGuidUtils.isFactoryGuid('env2'), isTrue);
      expect(AlgorithmGuidUtils.isFactoryGuid('abcd'), isTrue);
    });

    test('rejects community and non-factory GUIDs', () {
      expect(AlgorithmGuidUtils.isFactoryGuid('PLUG'), isFalse);
      expect(AlgorithmGuidUtils.isFactoryGuid('Plg1'), isFalse);
      expect(AlgorithmGuidUtils.isFactoryGuid('plug-in'), isFalse);
    });
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/ui/section_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("SectionBuilder Tests", () {
    test("can build sections for spin algorithm", () async {
      final slot = Slot(
        algorithmGuid: AlgorithmGuid(algorithmIndex: 1, guid: 'spin'),
        routing: RoutingInfo.filler(),
        parameters: [
          ParameterInfo(
              algorithmIndex: 1,
              parameterNumber: 1,
              min: 0,
              max: 1,
              defaultValue: 0,
              unit: 0,
              name: "Bypass",
              powerOfTen: 0),
          ParameterInfo(
              algorithmIndex: 1,
              parameterNumber: 2,
              min: 0,
              max: 1,
              defaultValue: 0,
              unit: 0,
              name: "Program",
              powerOfTen: 0)
        ],
        values: [],
        enums: [],
        mappings: [],
        valueStrings: [],
      );

      final sections = await SectionBuilder(slot: slot).buildSections();
      print(sections);

      expect(sections, isNotNull);

      expect(
        listEquals(
          sections!['Algorithm'],
          [
            ParameterInfo(
                algorithmIndex: 1,
                parameterNumber: 1,
                min: 0,
                max: 1,
                defaultValue: 0,
                unit: 0,
                name: "Bypass",
                powerOfTen: 0),
          ],
        ),
        true,
      );

      expect(
        listEquals(
          sections['Program'],
          [
            ParameterInfo(
                algorithmIndex: 1,
                parameterNumber: 2,
                min: 0,
                max: 1,
                defaultValue: 0,
                unit: 0,
                name: "Program",
                powerOfTen: 0),
          ],
        ),
        true,
      );
    });
  });
}

import 'package:nt_helper/domain/disting_nt_sysex.dart';

extension ParameterNumberLookup<T extends HasParameterNumber> on Iterable<T> {
  T? byParameterNumber(int parameterNumber) {
    for (final entry in this) {
      if (entry.parameterNumber == parameterNumber) return entry;
    }
    return null;
  }
}

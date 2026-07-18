import 'package:collection/collection.dart';

/// Immutable, normalized metadata for one instantiated algorithm shape.
final class AlgorithmShapeSnapshot {
  AlgorithmShapeSnapshot({
    required List<int> specificationValues,
    required List<ShapeParameterAtom> parameters,
    required List<ShapePageAtom> pages,
    required List<ShapePageMembershipAtom> pageMemberships,
    required List<ShapeOutputUsageAtom> outputUsage,
  }) : specificationValues = List.unmodifiable(specificationValues),
       parameters = List.unmodifiable(parameters),
       pages = List.unmodifiable(pages),
       pageMemberships = List.unmodifiable(
         [...pageMemberships]..sort((a, b) => a.compareTo(b)),
       ),
       outputUsage = List.unmodifiable(
         [...outputUsage]..sort((a, b) => a.compareTo(b)),
       );

  final List<int> specificationValues;
  final List<ShapeParameterAtom> parameters;
  final List<ShapePageAtom> pages;
  final List<ShapePageMembershipAtom> pageMemberships;
  final List<ShapeOutputUsageAtom> outputUsage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlgorithmShapeSnapshot &&
          const DeepCollectionEquality().equals(
            specificationValues,
            other.specificationValues,
          ) &&
          const DeepCollectionEquality().equals(parameters, other.parameters) &&
          const DeepCollectionEquality().equals(pages, other.pages) &&
          const DeepCollectionEquality().equals(
            pageMemberships,
            other.pageMemberships,
          ) &&
          const DeepCollectionEquality().equals(outputUsage, other.outputUsage);

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(specificationValues),
    const DeepCollectionEquality().hash(parameters),
    const DeepCollectionEquality().hash(pages),
    const DeepCollectionEquality().hash(pageMemberships),
    const DeepCollectionEquality().hash(outputUsage),
  );
}

final class ShapeParameterAtom {
  ShapeParameterAtom({
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.rawUnitIndex,
    required this.powerOfTen,
    required this.ioFlags,
    required List<String> enumStrings,
  }) : enumStrings = List.unmodifiable(enumStrings);

  final String name;
  final int min;
  final int max;
  final int defaultValue;
  final int rawUnitIndex;
  final int powerOfTen;
  final int ioFlags;
  final List<String> enumStrings;

  ShapeParameterAtom copyWith({
    String? name,
    int? min,
    int? max,
    int? defaultValue,
    int? rawUnitIndex,
    int? powerOfTen,
    int? ioFlags,
    List<String>? enumStrings,
  }) => ShapeParameterAtom(
    name: name ?? this.name,
    min: min ?? this.min,
    max: max ?? this.max,
    defaultValue: defaultValue ?? this.defaultValue,
    rawUnitIndex: rawUnitIndex ?? this.rawUnitIndex,
    powerOfTen: powerOfTen ?? this.powerOfTen,
    ioFlags: ioFlags ?? this.ioFlags,
    enumStrings: enumStrings ?? this.enumStrings,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShapeParameterAtom &&
          name == other.name &&
          min == other.min &&
          max == other.max &&
          defaultValue == other.defaultValue &&
          rawUnitIndex == other.rawUnitIndex &&
          powerOfTen == other.powerOfTen &&
          ioFlags == other.ioFlags &&
          const ListEquality<String>().equals(enumStrings, other.enumStrings);

  @override
  int get hashCode => Object.hash(
    name,
    min,
    max,
    defaultValue,
    rawUnitIndex,
    powerOfTen,
    ioFlags,
    const ListEquality<String>().hash(enumStrings),
  );
}

final class ShapePageAtom {
  const ShapePageAtom({required this.name});

  final String name;

  ShapePageAtom copyWith({String? name}) =>
      ShapePageAtom(name: name ?? this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ShapePageAtom && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

final class ShapePageMembershipAtom {
  const ShapePageMembershipAtom({
    required this.pageIndex,
    required this.parameterNumber,
  });

  final int pageIndex;
  final int parameterNumber;

  int compareTo(ShapePageMembershipAtom other) {
    final pageComparison = pageIndex.compareTo(other.pageIndex);
    return pageComparison != 0
        ? pageComparison
        : parameterNumber.compareTo(other.parameterNumber);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShapePageMembershipAtom &&
          pageIndex == other.pageIndex &&
          parameterNumber == other.parameterNumber;

  @override
  int get hashCode => Object.hash(pageIndex, parameterNumber);
}

final class ShapeOutputUsageAtom {
  const ShapeOutputUsageAtom({
    required this.parameterNumber,
    required this.affectedParameterNumber,
  });

  final int parameterNumber;
  final int affectedParameterNumber;

  int compareTo(ShapeOutputUsageAtom other) {
    final parameterComparison = parameterNumber.compareTo(
      other.parameterNumber,
    );
    return parameterComparison != 0
        ? parameterComparison
        : affectedParameterNumber.compareTo(other.affectedParameterNumber);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShapeOutputUsageAtom &&
          parameterNumber == other.parameterNumber &&
          affectedParameterNumber == other.affectedParameterNumber;

  @override
  int get hashCode => Object.hash(parameterNumber, affectedParameterNumber);
}

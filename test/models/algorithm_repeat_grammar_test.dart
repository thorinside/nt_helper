import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/algorithm_repeat_grammar.dart';
import 'package:nt_helper/models/algorithm_shape_snapshot.dart';

void main() {
  group('AlgorithmRepeatGrammar', () {
    test('compact JSON round-trips all grammar types', () {
      final grammar = _quantizerGrammar();

      expect(
        AlgorithmRepeatGrammar.fromCompactJson(grammar.toCompactJson()),
        grammar,
      );
      expect(
        () => AlgorithmRepeatGrammar.fromCompactJson([99, [], []]),
        throwsFormatException,
      );
    });

    test('fixed-only grammar preserves topology with requested vector', () {
      final canonical = _fixedSnapshot();
      final grammar = AlgorithmRepeatGrammar(
        baselineSpecifications: [2],
        sections: const [],
      );

      final expanded = grammar.expand(canonical, [4]);

      expect(expanded.specificationValues, [4]);
      expect(expanded.parameters, canonical.parameters);
      expect(expanded.pages, canonical.pages);
      expect(expanded.pageMemberships, canonical.pageMemberships);
    });

    test(
      'Quantizer-style section expands parameters, pages, and references',
      () {
        final grammar = _quantizerGrammar();
        final canonical = _quantizerSnapshot();

        final one = grammar.expand(canonical, [1]);
        final four = grammar.expand(canonical, [4]);

        expect(one.parameters.map((parameter) => parameter.name), [
          'Mode',
          '1:CV input',
          '1:CV output',
        ]);
        expect(four.parameters.map((parameter) => parameter.name), [
          'Mode',
          '1:CV input',
          '1:CV output',
          '2:CV input',
          '2:CV output',
          '3:CV input',
          '3:CV output',
          '4:CV input',
          '4:CV output',
        ]);
        expect(four.pages.map((page) => page.name), [
          'Algorithm',
          'Channel 1',
          'Channel 2',
          'Channel 3',
          'Channel 4',
        ]);
        expect(
          four.pageMemberships,
          contains(
            const ShapePageMembershipAtom(pageIndex: 4, parameterNumber: 8),
          ),
        );
        expect(
          four.outputUsage,
          contains(
            const ShapeOutputUsageAtom(
              parameterNumber: 8,
              affectedParameterNumber: 7,
            ),
          ),
        );
      },
    );

    test('two disjoint sections can use one specification', () {
      final canonical = AlgorithmShapeSnapshot(
        specificationValues: [2],
        parameters: [
          _parameter('Input 1'),
          _parameter('Input 2'),
          _parameter('Fixed'),
          _parameter('Output 1'),
          _parameter('Output 2'),
        ],
        pages: const [],
        pageMemberships: const [],
        outputUsage: const [],
      );
      RepeatSection section(int firstStart, String suffix) => RepeatSection(
        specificationIndex: 0,
        countBias: 0,
        sourceOrdinal: 0,
        runs: [
          ShapeStreamRun(
            stream: ShapeStream.parameters,
            firstStart: firstStart,
            itemCount: 1,
          ),
        ],
        substitutions: [
          OrdinalTextSubstitution(
            stream: ShapeStream.parameters,
            rowOffset: 0,
            field: OrdinalField.parameterName,
            parts: [
              LiteralTextPart(suffix),
              const OrdinalTextPlaceholder(
                specificationIndex: 0,
                displayBias: 1,
              ),
            ],
          ),
        ],
        children: const [],
      );
      final grammar = AlgorithmRepeatGrammar(
        baselineSpecifications: [2],
        sections: [section(0, 'Input '), section(3, 'Output ')],
      );

      expect(grammar.expand(canonical, [3]).parameters.map((p) => p.name), [
        'Input 1',
        'Input 2',
        'Input 3',
        'Fixed',
        'Output 1',
        'Output 2',
        'Output 3',
      ]);
    });

    test('nested channels and sends expand in deterministic order', () {
      final canonical = AlgorithmShapeSnapshot(
        specificationValues: [2, 1],
        parameters: [
          _parameter('Channel 1'),
          _parameter('Channel 1 Send 1'),
          _parameter('Channel 2'),
          _parameter('Channel 2 Send 1'),
        ],
        pages: const [],
        pageMemberships: const [],
        outputUsage: const [],
      );
      final send = RepeatSection(
        specificationIndex: 1,
        countBias: 0,
        sourceOrdinal: 0,
        runs: const [
          ShapeStreamRun(
            stream: ShapeStream.parameters,
            firstStart: 1,
            itemCount: 1,
          ),
        ],
        substitutions: [
          OrdinalTextSubstitution(
            stream: ShapeStream.parameters,
            rowOffset: 0,
            field: OrdinalField.parameterName,
            parts: const [
              LiteralTextPart('Channel '),
              OrdinalTextPlaceholder(specificationIndex: 0, displayBias: 1),
              LiteralTextPart(' Send '),
              OrdinalTextPlaceholder(specificationIndex: 1, displayBias: 1),
            ],
          ),
        ],
        children: const [],
      );
      final channel = RepeatSection(
        specificationIndex: 0,
        countBias: 0,
        sourceOrdinal: 0,
        runs: const [
          ShapeStreamRun(
            stream: ShapeStream.parameters,
            firstStart: 0,
            itemCount: 2,
          ),
        ],
        substitutions: [
          OrdinalTextSubstitution(
            stream: ShapeStream.parameters,
            rowOffset: 0,
            field: OrdinalField.parameterName,
            parts: const [
              LiteralTextPart('Channel '),
              OrdinalTextPlaceholder(specificationIndex: 0, displayBias: 1),
            ],
          ),
        ],
        children: [send],
      );
      final grammar = AlgorithmRepeatGrammar(
        baselineSpecifications: [2, 1],
        sections: [channel],
      );

      expect(grammar.expand(canonical, [4, 2]).parameters.map((p) => p.name), [
        'Channel 1',
        'Channel 1 Send 1',
        'Channel 1 Send 2',
        'Channel 2',
        'Channel 2 Send 1',
        'Channel 2 Send 2',
        'Channel 3',
        'Channel 3 Send 1',
        'Channel 3 Send 2',
        'Channel 4',
        'Channel 4 Send 1',
        'Channel 4 Send 2',
      ]);
    });

    test('invalid runs and dangling references throw atomically', () {
      final invalid = AlgorithmRepeatGrammar(
        baselineSpecifications: [2],
        sections: [
          RepeatSection(
            specificationIndex: 0,
            countBias: 0,
            sourceOrdinal: 0,
            runs: const [
              ShapeStreamRun(
                stream: ShapeStream.parameters,
                firstStart: 99,
                itemCount: 1,
              ),
            ],
            substitutions: const [],
            children: const [],
          ),
        ],
      );
      expect(
        () => invalid.expand(_quantizerSnapshot(), [4]),
        throwsFormatException,
      );

      final dangling = AlgorithmRepeatGrammar(
        baselineSpecifications: [2],
        sections: [
          RepeatSection(
            specificationIndex: 0,
            countBias: 0,
            sourceOrdinal: 0,
            runs: const [
              ShapeStreamRun(
                stream: ShapeStream.parameters,
                firstStart: 1,
                itemCount: 2,
              ),
            ],
            substitutions: const [],
            children: const [],
          ),
        ],
      );
      expect(
        () => dangling.expand(_quantizerSnapshot(), [4]),
        throwsFormatException,
      );
    });
  });
}

AlgorithmRepeatGrammar _quantizerGrammar() {
  final channel = RepeatSection(
    specificationIndex: 0,
    countBias: 0,
    sourceOrdinal: 0,
    runs: const [
      ShapeStreamRun(
        stream: ShapeStream.parameters,
        firstStart: 1,
        itemCount: 2,
      ),
      ShapeStreamRun(stream: ShapeStream.pages, firstStart: 1, itemCount: 1),
      ShapeStreamRun(
        stream: ShapeStream.memberships,
        firstStart: 1,
        itemCount: 2,
      ),
      ShapeStreamRun(
        stream: ShapeStream.outputUsage,
        firstStart: 0,
        itemCount: 1,
      ),
    ],
    substitutions: [
      for (final (offset, suffix) in const [(0, 'CV input'), (1, 'CV output')])
        OrdinalTextSubstitution(
          stream: ShapeStream.parameters,
          rowOffset: offset,
          field: OrdinalField.parameterName,
          parts: [
            const OrdinalTextPlaceholder(specificationIndex: 0, displayBias: 1),
            LiteralTextPart(':$suffix'),
          ],
        ),
      OrdinalTextSubstitution(
        stream: ShapeStream.pages,
        rowOffset: 0,
        field: OrdinalField.pageName,
        parts: const [
          LiteralTextPart('Channel '),
          OrdinalTextPlaceholder(specificationIndex: 0, displayBias: 1),
        ],
      ),
    ],
    children: const [],
  );
  return AlgorithmRepeatGrammar(
    baselineSpecifications: [2],
    sections: [channel],
  );
}

AlgorithmShapeSnapshot _fixedSnapshot() => AlgorithmShapeSnapshot(
  specificationValues: [2],
  parameters: [_parameter('Mode')],
  pages: const [ShapePageAtom(name: 'Algorithm')],
  pageMemberships: const [
    ShapePageMembershipAtom(pageIndex: 0, parameterNumber: 0),
  ],
  outputUsage: const [],
);

AlgorithmShapeSnapshot _quantizerSnapshot() => AlgorithmShapeSnapshot(
  specificationValues: [2],
  parameters: [
    _parameter('Mode'),
    _parameter('1:CV input'),
    _parameter('1:CV output'),
    _parameter('2:CV input'),
    _parameter('2:CV output'),
  ],
  pages: const [
    ShapePageAtom(name: 'Algorithm'),
    ShapePageAtom(name: 'Channel 1'),
    ShapePageAtom(name: 'Channel 2'),
  ],
  pageMemberships: const [
    ShapePageMembershipAtom(pageIndex: 0, parameterNumber: 0),
    ShapePageMembershipAtom(pageIndex: 1, parameterNumber: 1),
    ShapePageMembershipAtom(pageIndex: 1, parameterNumber: 2),
    ShapePageMembershipAtom(pageIndex: 2, parameterNumber: 3),
    ShapePageMembershipAtom(pageIndex: 2, parameterNumber: 4),
  ],
  outputUsage: const [
    ShapeOutputUsageAtom(parameterNumber: 2, affectedParameterNumber: 1),
    ShapeOutputUsageAtom(parameterNumber: 4, affectedParameterNumber: 3),
  ],
);

ShapeParameterAtom _parameter(String name) => ShapeParameterAtom(
  name: name,
  min: 0,
  max: 64,
  defaultValue: 0,
  rawUnitIndex: 0,
  powerOfTen: 0,
  ioFlags: 0,
  enumStrings: const [],
);

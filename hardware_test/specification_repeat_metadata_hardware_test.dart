import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/models/algorithm_shape_snapshot.dart';
import 'package:nt_helper/services/metadata_import_service.dart';
import 'package:nt_helper/services/offline_algorithm_shape_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpOverrides? previousHttpOverrides;
  late AppDatabase database;
  late OfflineAlgorithmShapeResolver resolver;
  late _McpClient mcp;
  late Map<String, Object?> originalPreset;

  setUpAll(() async {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = null;

    final source = await File(
      'assets/metadata/full_metadata.json',
    ).readAsString();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    expect(
      await MetadataImportService(database).importFromJson(source),
      isTrue,
      reason: 'The bundled metadata fixture must import before hardware QA.',
    );
    resolver = OfflineAlgorithmShapeResolver(database.metadataDao);

    final endpoint = Uri.parse(
      Platform.environment['NT_HELPER_MCP_URL'] ?? 'http://127.0.0.1:3847/mcp',
    );
    mcp = _McpClient(endpoint);
    await mcp.initialize();

    final preset = await mcp.callJson('show_preset');
    expect(
      preset['name'],
      isA<String>(),
      reason:
          'Hardware QA requires a synchronized physical NT. In nt_helper, '
          'wait for the MCP status light to turn green before running this suite.',
    );
    originalPreset = _presetIdentity(preset);
  });

  tearDownAll(() async {
    await mcp.close();
    await database.close();
    HttpOverrides.global = previousHttpOverrides;
  });

  test(
    'physical NT repeat shapes exactly match bundled offline metadata',
    () async {
      const cases = <_HardwareCase>[
        _HardwareCase('quan', [1]),
        _HardwareCase('quan', [4]),
        _HardwareCase('quan', [12]),
        _HardwareCase('mix1', [1, 0]),
        _HardwareCase('mix1', [2, 1]),
        _HardwareCase('mix1', [4, 2]),
      ];

      for (final hardwareCase in cases) {
        final resolved = await resolver.resolve(
          hardwareCase.guid,
          hardwareCase.specifications,
        );
        expect(
          resolved.usedGrammar,
          isTrue,
          reason:
              '${hardwareCase.label}: bundled metadata must use its repeat grammar.',
        );

        int? temporarySlot;
        try {
          final addResult = await mcp.callJson('add', {
            'guid': hardwareCase.guid,
            'specifications': hardwareCase.specifications,
          });
          _expectToolSuccess(addResult, 'add ${hardwareCase.label}');
          temporarySlot = addResult['slot_index'] as int?;
          expect(
            temporarySlot,
            isNotNull,
            reason: 'add ${hardwareCase.label} did not return slot_index.',
          );

          final metadata = await _pollForSlotMetadata(
            mcp,
            temporarySlot!,
            hardwareCase,
          );
          final live = _snapshotFromJson(metadata);

          expect(
            metadata['algorithm'],
            isA<Map>().having(
              (value) => value['guid'],
              'guid',
              hardwareCase.guid,
            ),
            reason: hardwareCase.label,
          );
          _expectShapeEquals(
            live,
            resolved.snapshot,
            label: hardwareCase.label,
          );
        } finally {
          if (temporarySlot != null) {
            final removeResult = await mcp.callJson('remove', {
              'slot_index': temporarySlot,
            });
            _expectToolSuccess(
              removeResult,
              'remove temporary ${hardwareCase.label}',
            );
            await _waitForPreset(mcp, originalPreset);
          }
        }
      }

      expect(
        _presetIdentity(await mcp.callJson('show_preset')),
        originalPreset,
        reason:
            'Hardware QA must leave the user\'s preset name and slot layout unchanged.',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

final class _HardwareCase {
  const _HardwareCase(this.guid, this.specifications);

  final String guid;
  final List<int> specifications;

  String get label => '$guid ${specifications.join('x')}';
}

Future<Map<String, dynamic>> _pollForSlotMetadata(
  _McpClient mcp,
  int slotIndex,
  _HardwareCase hardwareCase,
) async {
  Object? lastFailure;
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    try {
      final result = await mcp.callJson('show_slot_metadata', {
        'slot_index': slotIndex,
      });
      if (result['success'] == true &&
          _intList(result['specification_values']).toString() ==
              hardwareCase.specifications.toString()) {
        return result;
      }
      lastFailure = result;
    } catch (error) {
      lastFailure = error;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  fail(
    'Timed out waiting for ${hardwareCase.label} metadata in slot $slotIndex. '
    'Last response: $lastFailure',
  );
}

Future<void> _waitForPreset(
  _McpClient mcp,
  Map<String, Object?> expected,
) async {
  Map<String, Object?>? lastPreset;
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    lastPreset = _presetIdentity(await mcp.callJson('show_preset'));
    if (_deepEquals(lastPreset, expected)) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  fail('Preset was not restored after hardware QA. Last state: $lastPreset');
}

Map<String, Object?> _presetIdentity(Map<String, dynamic> preset) => {
  'name': preset['name'],
  'slots': [
    for (final slot in (preset['slots'] as List<dynamic>? ?? const []))
      {
        'slot_index': (slot as Map)['slot_index'],
        'algorithm': {
          'guid': (slot['algorithm'] as Map)['guid'],
          'name': (slot['algorithm'] as Map)['name'],
        },
        'parameter_count': slot['parameter_count'],
      },
  ],
};

AlgorithmShapeSnapshot _snapshotFromJson(Map<String, dynamic> json) {
  final parameters = (json['parameters'] as List<dynamic>).cast<Map>();
  final pages = (json['pages'] as List<dynamic>).cast<Map>();
  final memberships = (json['page_memberships'] as List<dynamic>).cast<Map>();
  final outputUsage = (json['output_usage'] as List<dynamic>).cast<Map>();
  return AlgorithmShapeSnapshot(
    specificationValues: _intList(json['specification_values']),
    parameters: [
      for (final parameter in parameters)
        ShapeParameterAtom(
          name: parameter['name'] as String,
          min: parameter['min'] as int,
          max: parameter['max'] as int,
          defaultValue: parameter['default_value'] as int,
          rawUnitIndex: parameter['raw_unit_index'] as int,
          powerOfTen: parameter['power_of_ten'] as int,
          ioFlags: parameter['io_flags'] as int,
          enumStrings: (parameter['enum_strings'] as List<dynamic>).cast(),
        ),
    ],
    pages: [
      for (final page in pages) ShapePageAtom(name: page['name'] as String),
    ],
    pageMemberships: [
      for (final membership in memberships)
        ShapePageMembershipAtom(
          pageIndex: membership['page_index'] as int,
          parameterNumber: membership['parameter_number'] as int,
        ),
    ],
    outputUsage: [
      for (final edge in outputUsage)
        ShapeOutputUsageAtom(
          parameterNumber: edge['parameter_number'] as int,
          affectedParameterNumber: edge['affected_parameter_number'] as int,
        ),
    ],
  );
}

List<int> _intList(Object? value) =>
    (value as List<dynamic>? ?? const []).cast<int>();

void _expectToolSuccess(Map<String, dynamic> result, String operation) {
  expect(
    result['success'],
    isTrue,
    reason: '$operation failed: ${result['error'] ?? result}',
  );
}

void _expectShapeEquals(
  AlgorithmShapeSnapshot actual,
  AlgorithmShapeSnapshot expected, {
  required String label,
}) {
  expect(
    actual.specificationValues,
    expected.specificationValues,
    reason: '$label specification values',
  );
  expect(
    actual.parameters,
    expected.parameters,
    reason: '$label parameters: ${_parameterDifference(actual, expected)}',
  );
  expect(actual.pages, expected.pages, reason: '$label pages');
  expect(
    actual.pageMemberships,
    expected.pageMemberships,
    reason: '$label page memberships',
  );
  expect(
    actual.outputUsage,
    expected.outputUsage,
    reason: '$label output-mode usage',
  );
}

String _parameterDifference(
  AlgorithmShapeSnapshot actual,
  AlgorithmShapeSnapshot expected,
) {
  final sharedLength = actual.parameters.length < expected.parameters.length
      ? actual.parameters.length
      : expected.parameters.length;
  for (var index = 0; index < sharedLength; index++) {
    if (actual.parameters[index] != expected.parameters[index]) {
      return 'index $index; live=${_describeParameter(actual.parameters[index])}; '
          'offline=${_describeParameter(expected.parameters[index])}';
    }
  }
  return 'live count ${actual.parameters.length}; '
      'offline count ${expected.parameters.length}';
}

Map<String, Object?> _describeParameter(ShapeParameterAtom parameter) => {
  'name': parameter.name,
  'min': parameter.min,
  'max': parameter.max,
  'default': parameter.defaultValue,
  'raw_unit_index': parameter.rawUnitIndex,
  'power_of_ten': parameter.powerOfTen,
  'io_flags': parameter.ioFlags,
  'enum_strings': parameter.enumStrings,
};

bool _deepEquals(Object? left, Object? right) =>
    jsonEncode(left) == jsonEncode(right);

final class _McpClient {
  _McpClient(this.endpoint);

  final Uri endpoint;
  final HttpClient _httpClient = HttpClient();
  String? _sessionId;
  var _nextId = 1;

  Future<void> initialize() async {
    final response = await _post({
      'jsonrpc': '2.0',
      'id': _nextId++,
      'method': 'initialize',
      'params': {
        'protocolVersion': '2025-06-18',
        'capabilities': <String, dynamic>{},
        'clientInfo': {'name': 'nt-helper-hardware-test', 'version': '1.0.0'},
      },
    });
    _sessionId = response.sessionId;
    if (_sessionId == null) {
      throw StateError(
        'nt_helper MCP did not create a session. Wait for its status light to '
        'turn green, then rerun the hardware suite.',
      );
    }
    _unwrapJsonRpc(response.message);

    await _post({
      'jsonrpc': '2.0',
      'method': 'notifications/initialized',
    }, expectMessage: false);
  }

  Future<Map<String, dynamic>> callJson(
    String tool, [
    Map<String, dynamic> arguments = const {},
  ]) async {
    final response = await _post({
      'jsonrpc': '2.0',
      'id': _nextId++,
      'method': 'tools/call',
      'params': {'name': tool, 'arguments': arguments},
    });
    final rpcResult = _unwrapJsonRpc(response.message);
    final content = rpcResult['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) {
      throw StateError('$tool returned no text content: $rpcResult');
    }
    final text = (content.first as Map)['text'] as String?;
    if (text == null) {
      throw StateError('$tool returned non-text content: $content');
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw StateError('$tool returned a non-object JSON payload: $decoded');
    }
    final result = decoded.cast<String, dynamic>();
    if (result['type'] == 'tool_reference') {
      return _readReference(result);
    }
    return result;
  }

  Future<Map<String, dynamic>> _readReference(
    Map<String, dynamic> reference,
  ) async {
    final totalChars = reference['total_chars'] as int;
    final referenceId = reference['reference_id'] as String;
    final buffer = StringBuffer();
    var offset = 0;
    while (offset < totalChars) {
      final page = await callJson('read_reference', {
        'reference_id': referenceId,
        'offset': offset,
        'limit': 16000,
      });
      _expectToolSuccess(page, 'read reference $referenceId');
      buffer.write(page['content'] as String);
      final nextOffset = page['next_offset'] as int?;
      if (nextOffset == null) break;
      offset = nextOffset;
    }
    final decoded = jsonDecode(buffer.toString());
    if (decoded is! Map) {
      throw StateError('Reference $referenceId did not contain a JSON object.');
    }
    return decoded.cast<String, dynamic>();
  }

  Map<String, dynamic> _unwrapJsonRpc(Map<String, dynamic>? message) {
    if (message == null) {
      throw StateError('nt_helper MCP returned no JSON-RPC response.');
    }
    final error = message['error'];
    if (error != null) throw StateError('MCP JSON-RPC error: $error');
    final result = message['result'];
    if (result is! Map) {
      throw StateError('MCP JSON-RPC response has no result: $message');
    }
    return result.cast<String, dynamic>();
  }

  Future<_McpResponse> _post(Object body, {bool expectMessage = true}) async {
    final request = await _httpClient.postUrl(endpoint);
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/json, text/event-stream')
      ..set(HttpHeaders.contentTypeHeader, 'application/json');
    if (_sessionId case final sessionId?) {
      request.headers.set('mcp-session-id', sessionId);
    }
    request.write(jsonEncode(body));
    final response = await request.close().timeout(const Duration(seconds: 45));
    final sessionId = response.headers.value('mcp-session-id');
    final responseBody = await utf8
        .decodeStream(response)
        .timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'nt_helper MCP returned HTTP ${response.statusCode}: $responseBody',
        uri: endpoint,
      );
    }
    if (!expectMessage) {
      return _McpResponse(sessionId: sessionId, message: null);
    }
    return _McpResponse(
      sessionId: sessionId,
      message: _decodeMessage(responseBody),
    );
  }

  Map<String, dynamic> _decodeMessage(String body) {
    if (body.trimLeft().startsWith('{')) {
      return (jsonDecode(body) as Map).cast<String, dynamic>();
    }
    for (final block in body.split(RegExp(r'\r?\n\r?\n'))) {
      final data = block
          .split(RegExp(r'\r?\n'))
          .where((line) => line.startsWith('data:'))
          .map((line) => line.substring('data:'.length).trimLeft())
          .join('\n')
          .trim();
      if (data.isEmpty) continue;
      final decoded = jsonDecode(data);
      if (decoded is Map && decoded['jsonrpc'] == '2.0') {
        return decoded.cast<String, dynamic>();
      }
    }
    throw FormatException('No JSON-RPC message in MCP response: $body');
  }

  Future<void> close() async {
    if (_sessionId case final sessionId?) {
      try {
        final request = await _httpClient.deleteUrl(endpoint);
        request.headers
          ..set(HttpHeaders.acceptHeader, 'application/json, text/event-stream')
          ..set('mcp-session-id', sessionId);
        final response = await request.close().timeout(
          const Duration(seconds: 5),
        );
        await response.drain<void>();
      } catch (_) {
        // The app may have closed after the test; the preset cleanup already ran.
      }
    }
    _httpClient.close(force: true);
  }
}

final class _McpResponse {
  const _McpResponse({required this.sessionId, required this.message});

  final String? sessionId;
  final Map<String, dynamic>? message;
}

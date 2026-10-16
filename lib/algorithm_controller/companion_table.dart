import 'package:nt_helper/domain/patch_map/patch_map.dart';

/// Validated host primitives. Lua chooses labels, field bindings, sections and
/// minimap geometry; the host owns widgets, focus, scrolling and the MIDI queue.
class CompanionTable {
  CompanionTable._(
    this.groups,
    this.labels,
    this.focusSocket,
    this.actions,
    this.recordSections,
    this.focusRecord,
    this.tableId,
    this.columns,
  );
  final String tableId;
  final List<CompanionColumn> columns;
  final int? focusSocket;
  final (String, int)? focusRecord;
  final List<CompanionRecordSection> recordSections;
  final List<CompanionChoiceAction> actions;
  final List<CompanionSocketGroup> groups;
  final Map<String, String> labels;

  factory CompanionTable.parse(Map<String, dynamic> document, PatchMap map) {
    if (document['type'] != 'socket_table' || document['version'] != 1) {
      throw const FormatException('Unsupported companion view');
    }
    final rawGroups = document['groups'];
    final rawLabels = document['labels'];
    if (rawGroups is! List || rawLabels is! Map) {
      throw const FormatException('Invalid companion table');
    }
    final groups = <CompanionSocketGroup>[];
    final sockets = <int>{};
    for (final group in rawGroups) {
      if (group is! Map) throw const FormatException('Invalid socket group');
      final start = group['start'],
          count = group['count'],
          columns = group['columns'];
      if (start is! int ||
          count is! int ||
          columns is! int ||
          start < 0 ||
          count < 1 ||
          columns < 1 ||
          columns > count ||
          count % columns != 0 ||
          start + count > map.connections.length) {
        throw const FormatException('Invalid socket grid');
      }
      for (var i = start; i < start + count; i++) {
        if (!sockets.add(i)) throw const FormatException('Duplicate socket');
      }
      groups.add(
        CompanionSocketGroup(
          start,
          count,
          columns,
          _label(group['title']),
          _label(group['short']),
        ),
      );
    }
    if (sockets.length != map.connections.length) {
      throw const FormatException('Companion omitted sockets');
    }
    final focus = document['focus_socket'];
    if (focus != null &&
        (focus is! int || focus < 0 || focus >= map.connections.length)) {
      throw const FormatException('Invalid focused socket');
    }
    final rawActions = document['actions'] ?? const [];
    if (rawActions is! List) {
      throw const FormatException('Invalid companion actions');
    }
    final actions = rawActions.map(CompanionChoiceAction.parse).toList();
    if (actions.map((action) => action.id).toSet().length != actions.length) {
      throw const FormatException('Duplicate companion action');
    }
    final rawSections = document['record_sections'] ?? const [];
    if (rawSections is! List || rawSections.length > 8) {
      throw const FormatException('Invalid record sections');
    }
    final sections = [
      for (final raw in rawSections)
        CompanionRecordSection.parse(raw, map.companionRecordSets),
    ];
    if (sections.map((section) => section.id).toSet().length !=
            sections.length ||
        sections.map((section) => section.source).toSet().length !=
            sections.length) {
      throw const FormatException('Duplicate record section');
    }
    final tableId = document['table_id'] == null
        ? 'sockets'
        : _label(document['table_id']);
    if (sections.any((section) => section.id == tableId)) {
      throw const FormatException('Duplicate table identity');
    }
    for (final section in sections) {
      if (!groups.any(
            (group) => group.start + group.count - 1 == section.afterSocket,
          ) ||
          (section.addAction != null &&
              !actions.any((action) => action.id == section.addAction))) {
        throw const FormatException('Invalid section placement or action');
      }
    }
    for (final source in map.companionRecordSets.entries) {
      if (source.value.isNotEmpty &&
          !sections.any((section) => section.source == source.key)) {
        throw const FormatException(
          'Update the SD companion to display all records',
        );
      }
    }
    (String, int)? focusRecord;
    final focusData = document['focus_record'];
    if (focusData != null) {
      if (focusData is! Map ||
          focusData['source'] is! String ||
          focusData['id'] is! int) {
        throw const FormatException('Invalid focused record');
      }
      final source = focusData['source'] as String;
      final identity = focusData['id'] as int;
      final matching = sections.where((section) => section.source == source);
      if (matching.isEmpty ||
          !map.companionRecordSets[source]!.any(
            (row) => row[matching.first.identity] == identity,
          )) {
        throw const FormatException('Unknown focused record');
      }
      focusRecord = (source, identity);
    }
    return CompanionTable._(
      List.unmodifiable(groups),
      {
        for (final field in ['socket', 'destination', 'colour', 'tag', 'group'])
          field: _label(rawLabels[field]),
      },
      focus as int?,
      List.unmodifiable(actions),
      List.unmodifiable(sections),
      focusRecord,
      tableId,
      CompanionColumn.socketColumns(document['columns'], rawLabels),
    );
  }
  static String _label(Object? value) {
    if (value is! String || value.isEmpty || value.length > 128) {
      throw const FormatException('Invalid companion label');
    }
    return value;
  }
}

class CompanionSocketGroup {
  const CompanionSocketGroup(
    this.start,
    this.count,
    this.columns,
    this.title,
    this.short,
  );
  final int start, count, columns;
  final String title, short;
}

/// Lua declares a choice dialog; the host retains a narrow action capability.
class CompanionChoiceAction {
  const CompanionChoiceAction._(
    this.id,
    this.label,
    this.title,
    this.cancel,
    this.choices,
  );
  final String id, label, title, cancel;
  final Map<int, String> choices;

  factory CompanionChoiceAction.parse(Object? value) {
    if (value is! Map) {
      throw const FormatException('Unsupported companion action');
    }
    final dialog = value['dialog'];
    if (dialog is! Map ||
        dialog['type'] != 'choice_dialog' ||
        dialog['choices'] is! List) {
      throw const FormatException('Invalid companion dialog');
    }
    final choices = <int, String>{};
    for (final choice in dialog['choices'] as List) {
      if (choice is! Map || choice['value'] is! int) {
        throw const FormatException('Invalid dialog choice');
      }
      final model = choice['value'] as int;
      if (model < 0 || model > 127 || choices.containsKey(model)) {
        throw const FormatException('Invalid expander choice');
      }
      choices[model] = CompanionTable._label(choice['label']);
    }
    if (choices.isEmpty) throw const FormatException('Empty companion dialog');
    return CompanionChoiceAction._(
      CompanionTable._label(value['id']),
      CompanionTable._label(value['label']),
      CompanionTable._label(dialog['title']),
      CompanionTable._label(dialog['cancel']),
      Map.unmodifiable(choices),
    );
  }
}

/// A table bound to a named record set supplied by the algorithm adapter.
/// Its labels, text columns, placement and actions all come from Lua.
class CompanionRecordSection {
  CompanionRecordSection._(
    this.id,
    this.source,
    this.identity,
    this.title,
    this.short,
    this.rowLabel,
    this.identityLabel,
    this.afterSocket,
    this.columns,
    this.addAction,
    this.removeEvent,
    this.removeLabel,
    this.confirmation,
  );
  final String id, source, identity, title, short, rowLabel, identityLabel;
  final int afterSocket;
  final List<CompanionColumn> columns;
  List<CompanionColumn> get fields =>
      columns.where((column) => column.type == 'text').toList();
  final String? addAction;
  final String removeEvent, removeLabel;
  final CompanionConfirmation confirmation;

  String label(Map<String, dynamic> record) => '$rowLabel ${record[identity]}';

  factory CompanionRecordSection.parse(
    Object? value,
    Map<String, List<Map<String, dynamic>>> sets,
  ) {
    if (value is! Map ||
        value['after_socket'] is! int ||
        value['columns'] is! List) {
      throw const FormatException('Invalid record section');
    }
    final source = CompanionTable._label(value['source']);
    final identity = CompanionTable._label(value['identity']);
    final records = sets[source];
    if (records == null) throw const FormatException('Unknown record source');
    final columns = CompanionColumn.parseList(value['columns']);
    final fields = columns.where((column) => column.type == 'text').toList();
    if (!columns.any(
          (column) => column.key == identity && column.type == 'label',
        ) ||
        columns.any(
          (column) => !const {'label', 'text', 'remove'}.contains(column.type),
        )) {
      throw const FormatException('Invalid record columns');
    }
    if (fields.isEmpty ||
        fields.length > 4 ||
        fields.map((field) => field.key).toSet().length != fields.length) {
      throw const FormatException('Invalid record fields');
    }
    final identities = <int>{};
    for (final row in records) {
      final id = row[identity];
      if (id is! int || !identities.add(id)) {
        throw const FormatException('Invalid record identity');
      }
      for (final field in fields) {
        final text = row[field.key];
        if (text is! String || text.length > field.maxLength) {
          throw const FormatException('Invalid bound text field');
        }
      }
    }
    return CompanionRecordSection._(
      CompanionTable._label(value['id']),
      source,
      identity,
      CompanionTable._label(value['title']),
      CompanionTable._label(value['short']),
      CompanionTable._label(value['row_label']),
      CompanionTable._label(value['identity_label']),
      value['after_socket'] as int,
      columns,
      value['add_action'] == null
          ? null
          : CompanionTable._label(value['add_action']),
      CompanionTable._label(value['remove_event']),
      CompanionTable._label(value['remove_label']),
      CompanionConfirmation.parse(value['confirmation']),
    );
  }
}

class CompanionColumn {
  const CompanionColumn(
    this.key,
    this.type,
    this.label,
    this.width,
    this.minWidth,
    this.maxWidth,
    this.flex,
    this.maxLength,
  );
  final String key, type, label;
  final double width, minWidth, maxWidth;
  final int flex, maxLength;

  factory CompanionColumn.parse(Object? value) {
    if (value is! Map) throw const FormatException('Invalid table column');
    final key = CompanionTable._label(value['key']), type = value['type'];
    if (!RegExp(r'^[a-z][a-z0-9_]{0,31}$').hasMatch(key) ||
        !const {
          'label',
          'text',
          'colour',
          'integer',
          'remove',
        }.contains(type)) {
      throw const FormatException('Invalid column binding or type');
    }
    final width = value['width'],
        minimum = value['min_width'] ?? 48,
        maximum = value['max_width'] ?? 1200;
    final flex = value['flex'] ?? 0, length = value['max_length'] ?? 32;
    if (width is! num ||
        minimum is! num ||
        maximum is! num ||
        !width.isFinite ||
        !minimum.isFinite ||
        !maximum.isFinite ||
        minimum < 32 ||
        maximum > 2000 ||
        width < minimum ||
        width > maximum ||
        flex is! int ||
        flex < 0 ||
        flex > 6 ||
        length is! int ||
        length < 1 ||
        length > 32) {
      throw const FormatException('Invalid column size or text limit');
    }
    return CompanionColumn(
      key,
      type as String,
      CompanionTable._label(value['label']),
      width.toDouble(),
      minimum.toDouble(),
      maximum.toDouble(),
      flex,
      length,
    );
  }

  static List<CompanionColumn> parseList(Object? value) {
    if (value is! List || value.isEmpty || value.length > 8) {
      throw const FormatException('Invalid table columns');
    }
    final columns = value.map(CompanionColumn.parse).toList();
    if (columns.map((column) => column.key).toSet().length != columns.length) {
      throw const FormatException('Duplicate table column');
    }
    return List.unmodifiable(columns);
  }

  static List<CompanionColumn> socketColumns(Object? value, Map labels) {
    final columns = value == null
        ? [
            CompanionColumn(
              'socket',
              'label',
              labels['socket'] as String,
              96,
              72,
              1200,
              0,
              32,
            ),
            CompanionColumn(
              'destination',
              'text',
              labels['destination'] as String,
              288,
              140,
              1200,
              3,
              32,
            ),
            CompanionColumn(
              'colour',
              'colour',
              labels['colour'] as String,
              126,
              112,
              1200,
              0,
              32,
            ),
            CompanionColumn(
              'tag',
              'integer',
              labels['tag'] as String,
              64,
              48,
              1200,
              0,
              32,
            ),
            CompanionColumn(
              'group',
              'text',
              labels['group'] as String,
              220,
              100,
              1200,
              2,
              32,
            ),
          ]
        : parseList(value);
    const types = {
      'socket': 'label',
      'destination': 'text',
      'colour': 'colour',
      'tag': 'integer',
      'group': 'text',
    };
    if (!columns.any((column) => column.key == 'socket') ||
        columns.any((column) => types[column.key] != column.type)) {
      throw const FormatException('Invalid socket field binding');
    }
    return List.unmodifiable(columns);
  }
}

class CompanionConfirmation {
  const CompanionConfirmation(
    this.title,
    this.message,
    this.cancel,
    this.confirm,
  );
  final String title, message, cancel, confirm;
  factory CompanionConfirmation.parse(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid removal confirmation');
    }
    return CompanionConfirmation(
      CompanionTable._label(value['title']),
      CompanionTable._label(value['message']),
      CompanionTable._label(value['cancel']),
      CompanionTable._label(value['confirm']),
    );
  }
}

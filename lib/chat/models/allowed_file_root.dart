enum FileRootActor {
  chat('chat'),
  mcp('mcp');

  const FileRootActor(this.storageKey);

  final String storageKey;

  static FileRootActor? fromStorageKey(String value) {
    for (final actor in values) {
      if (actor.storageKey == value) return actor;
    }
    return null;
  }
}

enum FileRootPermission {
  read('read'),
  write('write'),
  search('search');

  const FileRootPermission(this.storageKey);

  final String storageKey;

  static FileRootPermission? fromStorageKey(String value) {
    for (final permission in values) {
      if (permission.storageKey == value) return permission;
    }
    return null;
  }
}

class AllowedFileRoot {
  const AllowedFileRoot({
    required this.id,
    required this.label,
    required this.path,
    required this.acl,
  });

  factory AllowedFileRoot.chatReadSearch({
    required String id,
    required String label,
    required String path,
  }) {
    return AllowedFileRoot(
      id: id,
      label: label,
      path: path,
      acl: const {
        FileRootActor.chat: {
          FileRootPermission.read,
          FileRootPermission.search,
        },
      },
    );
  }

  factory AllowedFileRoot.fromJson(Map<String, dynamic> json) {
    final rawAcl = json['acl'];
    final acl = <FileRootActor, Set<FileRootPermission>>{};
    if (rawAcl is Map) {
      for (final entry in rawAcl.entries) {
        final actor = FileRootActor.fromStorageKey(entry.key.toString());
        if (actor == null) continue;
        final rawPermissions = entry.value;
        if (rawPermissions is! List) continue;
        acl[actor] = rawPermissions
            .whereType<String>()
            .map(FileRootPermission.fromStorageKey)
            .whereType<FileRootPermission>()
            .toSet();
      }
    }

    return AllowedFileRoot(
      id: _stringField(json, 'id'),
      label: _stringField(json, 'label'),
      path: _stringField(json, 'path'),
      acl: acl,
    );
  }

  final String id;
  final String label;
  final String path;
  final Map<FileRootActor, Set<FileRootPermission>> acl;

  Set<FileRootPermission> permissionsFor(FileRootActor actor) {
    return Set.unmodifiable(acl[actor] ?? const <FileRootPermission>{});
  }

  bool allows(FileRootActor actor, FileRootPermission permission) {
    return permissionsFor(actor).contains(permission);
  }

  AllowedFileRoot copyWith({
    String? id,
    String? label,
    String? path,
    Map<FileRootActor, Set<FileRootPermission>>? acl,
  }) {
    return AllowedFileRoot(
      id: id ?? this.id,
      label: label ?? this.label,
      path: path ?? this.path,
      acl: acl ?? this.acl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'path': path,
      'acl': {
        for (final actor in FileRootActor.values)
          actor.storageKey:
              (acl[actor] ?? const <FileRootPermission>{})
                  .map((permission) => permission.storageKey)
                  .toList()
                ..sort(),
      },
    };
  }

  bool get isValid => id.trim().isNotEmpty && path.trim().isNotEmpty;

  static String _stringField(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String ? value.trim() : '';
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_installations_dao.dart';

// ignore_for_file: type=lint
mixin _$PluginInstallationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PluginInstallationsTable get pluginInstallations =>
      attachedDatabase.pluginInstallations;
  PluginInstallationsDaoManager get managers =>
      PluginInstallationsDaoManager(this);
}

class PluginInstallationsDaoManager {
  final _$PluginInstallationsDaoMixin _db;
  PluginInstallationsDaoManager(this._db);
  $$PluginInstallationsTableTableManager get pluginInstallations =>
      $$PluginInstallationsTableTableManager(
        _db.attachedDatabase,
        _db.pluginInstallations,
      );
}

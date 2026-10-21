import 'dart:convert';

import 'package:nt_helper/models/gallery_models.dart';

String cache(String name, {String? stable}) => jsonEncode({
  'timestamp': DateTime.now().toIso8601String(),
  'gallery': Gallery(
    version: '1',
    lastUpdated: DateTime(2026),
    metadata: const GalleryMetadata(
      name: 'Gallery',
      description: 'Retained gallery',
      maintainer: GalleryMaintainer(name: 'Fixture'),
    ),
    plugins: [
      GalleryPlugin(
        id: 'retained',
        name: name,
        description: 'Retained cache description',
        type: GalleryPluginType.lua,
        author: 'Fixture',
        repository: const PluginRepository(
          owner: 'fixture',
          name: 'plugin',
          url: 'https://example.invalid',
        ),
        releases: PluginReleases(latest: '', stable: stable),
        guid: 'TEST',
        installation: const PluginInstallation(targetPath: '/programs/lua'),
      ),
    ],
  ).toJson(),
});

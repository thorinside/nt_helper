import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/services/sample_directory_listing_cache.dart';

class _MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  late SampleDirectoryListingCache cache;
  late _MockDistingMidiManager manager;

  setUp(() {
    cache = SampleDirectoryListingCache();
    manager = _MockDistingMidiManager();
  });

  test('shares in-flight and completed requests for the same path', () async {
    final completer = Completer<DirectoryListing?>();
    final listing = DirectoryListing(entries: const []);
    when(
      () => manager.requestDirectoryListing('/samples'),
    ).thenAnswer((_) => completer.future);

    final first = cache.request(manager, '/samples');
    final second = cache.request(manager, '/samples/');

    completer.complete(listing);
    expect(await first, same(listing));
    expect(await second, same(listing));
    expect(await cache.request(manager, '/samples'), same(listing));
    verify(() => manager.requestDirectoryListing('/samples')).called(1);
  });

  test(
    'invalidating a tree refreshes it without touching other paths',
    () async {
      when(
        () => manager.requestDirectoryListing(any()),
      ).thenAnswer((_) async => DirectoryListing(entries: const []));

      await cache.request(manager, '/samples');
      await cache.request(manager, '/samples/Drums');
      await cache.request(manager, '/presets');
      expect(cache.revisionFor(manager), 0);

      cache.invalidateTree(manager, '/samples/');

      expect(cache.revisionFor(manager), 1);
      await cache.request(manager, '/samples');
      await cache.request(manager, '/samples/Drums');
      await cache.request(manager, '/presets');

      verify(() => manager.requestDirectoryListing('/samples')).called(2);
      verify(() => manager.requestDirectoryListing('/samples/Drums')).called(2);
      verify(() => manager.requestDirectoryListing('/presets')).called(1);
    },
  );

  test('does not retain an unavailable listing', () async {
    var requestCount = 0;
    when(() => manager.requestDirectoryListing('/samples')).thenAnswer((
      _,
    ) async {
      requestCount++;
      if (requestCount == 1) return null;
      return DirectoryListing(entries: const []);
    });

    expect(await cache.request(manager, '/samples'), isNull);
    expect(await cache.request(manager, '/samples'), isNotNull);
    verify(() => manager.requestDirectoryListing('/samples')).called(2);
  });
}

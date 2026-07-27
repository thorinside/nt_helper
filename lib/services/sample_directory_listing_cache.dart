import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

/// Shares sample directory listings between parameter editors.
///
/// The cache is intentionally scoped to the file-browser UI. Other SD-card
/// workflows, such as uploads and installs, continue to request fresh listings.
class SampleDirectoryListingCache {
  SampleDirectoryListingCache();

  static final shared = SampleDirectoryListingCache();

  final Expando<_SampleDirectoryCacheState> _states =
      Expando<_SampleDirectoryCacheState>('sampleDirectoryListingCache');

  Future<DirectoryListing?> request(IDistingMidiManager manager, String path) {
    final normalizedPath = _normalizePath(path);
    final state = _stateFor(manager);
    final cached = state.listings[normalizedPath];
    if (cached != null) {
      return cached;
    }

    final request = manager.requestDirectoryListing(normalizedPath);
    state.listings[normalizedPath] = request;
    request.then(
      (listing) {
        if (listing == null &&
            identical(state.listings[normalizedPath], request)) {
          state.listings.remove(normalizedPath);
        }
      },
      onError: (_) {
        if (identical(state.listings[normalizedPath], request)) {
          state.listings.remove(normalizedPath);
        }
      },
    );
    return request;
  }

  int revisionFor(IDistingMidiManager manager) => _stateFor(manager).revision;

  void invalidateTree(IDistingMidiManager manager, String rootPath) {
    final normalizedRoot = _normalizePath(rootPath);
    final descendantPrefix = normalizedRoot == '/' ? '/' : '$normalizedRoot/';
    final state = _stateFor(manager);
    state.listings.removeWhere(
      (path, _) => path == normalizedRoot || path.startsWith(descendantPrefix),
    );
    state.revision++;
  }

  _SampleDirectoryCacheState _stateFor(IDistingMidiManager manager) {
    return _states[manager] ??= _SampleDirectoryCacheState();
  }

  String _normalizePath(String path) {
    if (path.length <= 1) return path;
    return path.replaceFirst(RegExp(r'/+$'), '');
  }
}

class _SampleDirectoryCacheState {
  final Map<String, Future<DirectoryListing?>> listings = {};
  int revision = 0;
}

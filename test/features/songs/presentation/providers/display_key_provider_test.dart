import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/songs/presentation/providers/display_key_provider.dart';
import 'package:worship_lamal/features/userkey/data/model/user_key_model.dart';
import 'package:worship_lamal/features/userkey/presentation/providers/user_keys_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [ProviderContainer] with the given overrides and attaches a
/// listener so auto-disposed providers stay alive for the duration of the
/// test.  Returns a [ProviderContainer]; callers must [dispose] it themselves
/// (or wrap in [addTearDown]).
ProviderContainer _makeContainer({List<Override> overrides = const []}) {
  final container = ProviderContainer.test(overrides: overrides);
  return container;
}

/// Shortcut: read [displayKeyProvider] for a given songId / originalKey.
String _read(
  ProviderContainer c, {
  required String songId,
  String? originalKey,
}) {
  return c.read(displayKeyProvider((songId: songId, originalKey: originalKey)));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  group('displayKeyProvider — priority 1: user preferred key override', () {
    test('returns the user-preferred key when map contains the song', () {
      final container = _makeContainer(
        overrides: [
          // Song "song-1" has a user-set preferred key of "F#"
          userPreferredKeysMapProvider.overrideWithValue({'song-1': 'F#'}),
          // Female vocal mode is ON — but user key takes precedence
          preferencesProvider.overrideWith(
            () => _StubPreferencesNotifier(VocalMode.female),
          ),
        ],
      );
      addTearDown(container.dispose);

      final key = _read(container, songId: 'song-1', originalKey: 'G');

      expect(key, 'F#');
    });

    test(
      'returns user-preferred key even when it differs from female transposition',
      () {
        final container = _makeContainer(
          overrides: [
            userPreferredKeysMapProvider.overrideWithValue({'song-1': 'Bb'}),
            preferencesProvider.overrideWith(
              () => _StubPreferencesNotifier(VocalMode.female),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Female of G would be D (G -5 semitones), but user set Bb
        final key = _read(container, songId: 'song-1', originalKey: 'G');

        expect(key, 'Bb');
      },
    );

    test('user-preferred key applies to the specific song only', () {
      final container = _makeContainer(
        overrides: [
          userPreferredKeysMapProvider.overrideWithValue({'song-1': 'F#'}),
          preferencesProvider.overrideWith(
            () => _StubPreferencesNotifier(VocalMode.original),
          ),
        ],
      );
      addTearDown(container.dispose);

      // song-2 is NOT in the map; should fall through to priority 3
      final key = _read(container, songId: 'song-2', originalKey: 'C');

      expect(key, 'C');
    });
  });

  // -------------------------------------------------------------------------
  group('displayKeyProvider — priority 2: female vocal -5 semitone shift', () {
    test('transposes original key down 5 semitones in female mode', () {
      final container = _makeContainer(
        overrides: [
          userPreferredKeysMapProvider.overrideWithValue({}), // no user key
          preferencesProvider.overrideWith(
            () => _StubPreferencesNotifier(VocalMode.female),
          ),
        ],
      );
      addTearDown(container.dispose);

      // G → down 5 → D
      final key = _read(container, songId: 'song-1', originalKey: 'G');

      expect(key, 'D');
    });

    test('transposes C down 5 semitones to G (wraps around scale)', () {
      final container = _makeContainer(
        overrides: [
          userPreferredKeysMapProvider.overrideWithValue({}),
          preferencesProvider.overrideWith(
            () => _StubPreferencesNotifier(VocalMode.female),
          ),
        ],
      );
      addTearDown(container.dispose);

      // C → down 5 → G
      final key = _read(container, songId: 'song-1', originalKey: 'C');

      expect(key, 'G');
    });

    test('skips female transposition when originalKey is empty', () {
      final container = _makeContainer(
        overrides: [
          userPreferredKeysMapProvider.overrideWithValue({}),
          preferencesProvider.overrideWith(
            () => _StubPreferencesNotifier(VocalMode.female),
          ),
        ],
      );
      addTearDown(container.dispose);

      // empty originalKey should fall to priority 3 → 'Unknown'
      final key = _read(container, songId: 'song-1', originalKey: '');

      expect(key, 'Unknown');
    });

    test('skips female transposition when originalKey is null', () {
      final container = _makeContainer(
        overrides: [
          userPreferredKeysMapProvider.overrideWithValue({}),
          preferencesProvider.overrideWith(
            () => _StubPreferencesNotifier(VocalMode.female),
          ),
        ],
      );
      addTearDown(container.dispose);

      final key = _read(container, songId: 'song-1', originalKey: null);

      expect(key, 'Unknown');
    });
  });

  // -------------------------------------------------------------------------
  group('displayKeyProvider — priority 3: original DB key', () {
    test(
      'returns original key when no user key and vocal mode is original',
      () {
        final container = _makeContainer(
          overrides: [
            userPreferredKeysMapProvider.overrideWithValue({}),
            preferencesProvider.overrideWith(
              () => _StubPreferencesNotifier(VocalMode.original),
            ),
          ],
        );
        addTearDown(container.dispose);

        final key = _read(container, songId: 'song-1', originalKey: 'Am');

        expect(key, 'Am');
      },
    );

    test('returns "Unknown" when originalKey is null and no user key', () {
      final container = _makeContainer(
        overrides: [
          userPreferredKeysMapProvider.overrideWithValue({}),
          preferencesProvider.overrideWith(
            () => _StubPreferencesNotifier(VocalMode.original),
          ),
        ],
      );
      addTearDown(container.dispose);

      final key = _read(container, songId: 'song-1', originalKey: null);

      expect(key, 'Unknown');
    });

    test('returns "Unknown" when originalKey is empty and no user key', () {
      final container = _makeContainer(
        overrides: [
          userPreferredKeysMapProvider.overrideWithValue({}),
          preferencesProvider.overrideWith(
            () => _StubPreferencesNotifier(VocalMode.original),
          ),
        ],
      );
      addTearDown(container.dispose);

      final key = _read(container, songId: 'song-1', originalKey: '');

      expect(key, 'Unknown');
    });
  });

  // -------------------------------------------------------------------------
  group(
    'userPreferredKeysMapProvider — derived map from userKeysListProvider',
    () {
      test('returns empty map while userKeysListProvider is loading', () {
        final container = _makeContainer(
          overrides: [
            // Simulate the FutureProvider still in-flight
            userKeysListProvider.overrideWith(
              (_) async =>
                  Future.delayed(const Duration(seconds: 60), () => []),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Keep the loading FutureProvider alive
        container.listen(userKeysListProvider, (_, __) {});

        final map = container.read(userPreferredKeysMapProvider);
        expect(map, isEmpty);
      });

      test(
        'returns populated map when userKeysListProvider has data',
        () async {
          final container = _makeContainer(
            overrides: [
              userKeysListProvider.overrideWith(
                (_) async => [
                  UserKey(userId: 'u1', songId: 'song-1', preferredKey: 'Eb'),
                  UserKey(userId: 'u1', songId: 'song-2', preferredKey: 'F#'),
                ],
              ),
            ],
          );
          addTearDown(container.dispose);

          // Attach listener to prevent auto-dispose; then await the future
          container.listen(userKeysListProvider, (_, __) {});
          await expectLater(
            container.read(userKeysListProvider.future),
            completes,
          );

          final map = container.read(userPreferredKeysMapProvider);
          expect(map, {'song-1': 'Eb', 'song-2': 'F#'});
        },
      );

      test('returns empty map when API returns empty list', () async {
        final container = _makeContainer(
          overrides: [userKeysListProvider.overrideWith((_) async => [])],
        );
        addTearDown(container.dispose);

        container.listen(userKeysListProvider, (_, __) {});
        await expectLater(
          container.read(userKeysListProvider.future),
          completion(isEmpty),
        );

        final map = container.read(userPreferredKeysMapProvider);
        expect(map, isEmpty);
      });

      test('returns empty map when userKeysListProvider errors', () async {
        final container = _makeContainer(
          overrides: [
            userKeysListProvider.overrideWith(
              (_) async => throw Exception('network failure'),
            ),
          ],
        );

        container.listen(userKeysListProvider, (_, __) {});
        await Future<void>.delayed(Duration.zero);

        // orElse returns {} on error
        final map = container.read(userPreferredKeysMapProvider);
        expect(map, isEmpty);
      });
    },
  );
}

// ---------------------------------------------------------------------------
// Stub helpers
// ---------------------------------------------------------------------------

/// A synchronous [PreferencesNotifier] stub that skips the SharedPreferences
/// I/O and immediately settles to the given [VocalMode].
class _StubPreferencesNotifier extends PreferencesNotifier {
  final VocalMode _vocalMode;
  _StubPreferencesNotifier(this._vocalMode);

  @override
  PreferencesState build() {
    return PreferencesState(vocalMode: _vocalMode, isLoading: false);
  }
}

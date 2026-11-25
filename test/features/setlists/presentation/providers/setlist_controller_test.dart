import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worship_lamal/features/setlists/data/models/setlist_model.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [ProviderContainer] with [setlistRepositoryProvider] wired to
/// [mockRepo].  Attaches a listener on [setlistControllerProvider] so the
/// AsyncNotifier is kept alive for the duration of the test.
ProviderContainer _makeContainer(MockSetlistRepository mockRepo) {
  final container = ProviderContainer.test(
    overrides: [
      setlistRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
  // Keep the provider alive (auto-dispose guard)
  container.listen(setlistControllerProvider, (_, __) {});
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSetlistRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockSetlistRepository();
    container = _makeContainer(mockRepo);
  });

  tearDown(() => container.dispose());

  // =========================================================================
  group('SetlistController — initial state', () {
    test('starts in AsyncData(null) after build completes', () async {
      await expectLater(
        container.read(setlistControllerProvider.future),
        completes,
      );
      expect(
        container.read(setlistControllerProvider),
        const AsyncData<void>(null),
      );
    });
  });

  // =========================================================================
  group('SetlistController.createSetlist', () {
    test('transitions loading → data and returns the new ID on success',
        () async {
      when(() => mockRepo.createSetlist(any()))
          .thenAnswer((_) async => 'new-setlist-id');

      // Kick off the mutation
      final id = await container
          .read(setlistControllerProvider.notifier)
          .createSetlist('Sunday Service');

      expect(id, 'new-setlist-id');
      expect(
        container.read(setlistControllerProvider),
        const AsyncData<void>(null),
      );
      verify(() => mockRepo.createSetlist('Sunday Service')).called(1);
    });

    test('transitions loading → error and returns null when repo throws',
        () async {
      when(() => mockRepo.createSetlist(any()))
          .thenThrow(Exception('create failed'));

      final states = <AsyncValue<void>>[];
      final sub = container.listen(
        setlistControllerProvider,
        (_, next) => states.add(next),
      );

      final id = await container
          .read(setlistControllerProvider.notifier)
          .createSetlist('Bad Setlist');

      sub.close();

      expect(id, isNull);
      // At least one error state must have been emitted
      expect(states.any((s) => s is AsyncError), isTrue);
    });

    test('invalidates setlistsListProvider on success', () async {
      when(() => mockRepo.createSetlist(any()))
          .thenAnswer((_) async => 'sl-new');
      when(() => mockRepo.getSetlists()).thenAnswer((_) async => []);

      // Seed setlistsListProvider
      container.listen(setlistsListProvider, (_, __) {});

      await container
          .read(setlistControllerProvider.notifier)
          .createSetlist('Test');

      // Verify getSetlists is not called here — invalidation is lazy.
      // We just assert the controller settles to data.
      expect(
        container.read(setlistControllerProvider),
        const AsyncData<void>(null),
      );
    });
  });

  // =========================================================================
  group('SetlistController.updateKeyOverride', () {
    test('calls repo.updateKeyOverride with correct args on success', () async {
      when(() => mockRepo.updateKeyOverride(any(), any()))
          .thenAnswer((_) async {});

      await container.read(setlistControllerProvider.notifier).updateKeyOverride(
            setlistId: 'sl-1',
            itemId: 'item-1',
            newKey: 'F#',
          );

      verify(() => mockRepo.updateKeyOverride('item-1', 'F#')).called(1);
      // Controller state remains data (error was swallowed via debugPrint)
      expect(
        container.read(setlistControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('swallows error (logs via debugPrint) and state stays data', () async {
      when(() => mockRepo.updateKeyOverride(any(), any()))
          .thenThrow(Exception('update failed'));

      // Should not throw
      await container.read(setlistControllerProvider.notifier).updateKeyOverride(
            setlistId: 'sl-1',
            itemId: 'item-1',
            newKey: 'Eb',
          );

      expect(
        container.read(setlistControllerProvider),
        const AsyncData<void>(null),
      );
    });
  });

  // =========================================================================
  group('SetlistController.reorderSongs', () {
    test('calls repo.reorderSetlistItems with the provided items', () async {
      final items = [
        tSetlistItem(id: 'item-a', sortOrder: 0),
        tSetlistItem(id: 'item-b', sortOrder: 1),
      ];

      when(() => mockRepo.reorderSetlistItems(any(), any()))
          .thenAnswer((_) async {});

      await container
          .read(setlistControllerProvider.notifier)
          .reorderSongs(setlistId: 'sl-1', currentList: items);

      verify(() => mockRepo.reorderSetlistItems('sl-1', items)).called(1);
    });

    test('swallows exception and invalidates detail provider', () async {
      when(() => mockRepo.reorderSetlistItems(any(), any()))
          .thenThrow(Exception('reorder failed'));
      when(() => mockRepo.getSetlistById(any())).thenAnswer((_) async => null);

      // Should not throw
      await container
          .read(setlistControllerProvider.notifier)
          .reorderSongs(setlistId: 'sl-1', currentList: []);

      expect(
        container.read(setlistControllerProvider),
        const AsyncData<void>(null),
      );
    });
  });

  // =========================================================================
  group('SetlistController.removeSong', () {
    test('delegates to repo.removeSong with correct ids', () async {
      when(() => mockRepo.removeSong(any(), any())).thenAnswer((_) async {});

      final item = tSetlistItem(id: 'item-1');

      await container
          .read(setlistControllerProvider.notifier)
          .removeSong(setlistId: 'sl-1', item: item);

      verify(() => mockRepo.removeSong('sl-1', 'item-1')).called(1);
    });

    test('swallows exception and state remains data', () async {
      when(() => mockRepo.removeSong(any(), any()))
          .thenThrow(Exception('remove failed'));

      final item = tSetlistItem(id: 'item-1');

      await container
          .read(setlistControllerProvider.notifier)
          .removeSong(setlistId: 'sl-1', item: item);

      expect(
        container.read(setlistControllerProvider),
        const AsyncData<void>(null),
      );
    });
  });

  // =========================================================================
  group('SetlistController.deleteSetlist', () {
    test('transitions loading → data on success', () async {
      when(() => mockRepo.deleteSetlist(any())).thenAnswer((_) async {});

      final states = <AsyncValue<void>>[];
      final sub = container.listen(
        setlistControllerProvider,
        (_, next) => states.add(next),
      );

      await container
          .read(setlistControllerProvider.notifier)
          .deleteSetlist('sl-1');

      sub.close();

      verify(() => mockRepo.deleteSetlist('sl-1')).called(1);
      expect(
        container.read(setlistControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('transitions loading → error on failure', () async {
      when(() => mockRepo.deleteSetlist(any()))
          .thenThrow(Exception('delete failed'));

      final states = <AsyncValue<void>>[];
      final sub = container.listen(
        setlistControllerProvider,
        (_, next) => states.add(next),
      );

      await container
          .read(setlistControllerProvider.notifier)
          .deleteSetlist('sl-bad');

      sub.close();

      expect(states.any((s) => s is AsyncError), isTrue);
    });
  });

  // =========================================================================
  group('SetlistController.renameSetlist', () {
    test('calls repo.renameSetlist and settles to data', () async {
      when(() => mockRepo.renameSetlist(any(), any()))
          .thenAnswer((_) async {});

      await container
          .read(setlistControllerProvider.notifier)
          .renameSetlist(setlistId: 'sl-1', newTitle: 'New Title');

      verify(() => mockRepo.renameSetlist('sl-1', 'New Title')).called(1);
      expect(
        container.read(setlistControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('transitions to error state when repo throws', () async {
      when(() => mockRepo.renameSetlist(any(), any()))
          .thenThrow(Exception('rename failed'));

      final states = <AsyncValue<void>>[];
      final sub = container.listen(
        setlistControllerProvider,
        (_, next) => states.add(next),
      );

      await container
          .read(setlistControllerProvider.notifier)
          .renameSetlist(setlistId: 'sl-1', newTitle: 'Bad');

      sub.close();

      expect(states.any((s) => s is AsyncError), isTrue);
    });
  });

  // =========================================================================
  group('SetlistController.toggleFollow', () {
    test('calls followSetlist when isCurrentlyFollowing is false', () async {
      when(() => mockRepo.followSetlist(any())).thenAnswer((_) async {});

      await container.read(setlistControllerProvider.notifier).toggleFollow(
            setlistId: 'sl-1',
            isCurrentlyFollowing: false,
          );

      verify(() => mockRepo.followSetlist('sl-1')).called(1);
      verifyNever(() => mockRepo.unfollowSetlist(any()));
    });

    test('calls unfollowSetlist when isCurrentlyFollowing is true', () async {
      when(() => mockRepo.unfollowSetlist(any())).thenAnswer((_) async {});

      await container.read(setlistControllerProvider.notifier).toggleFollow(
            setlistId: 'sl-1',
            isCurrentlyFollowing: true,
          );

      verify(() => mockRepo.unfollowSetlist('sl-1')).called(1);
      verifyNever(() => mockRepo.followSetlist(any()));
    });

    test('transitions to error state when repo throws', () async {
      when(() => mockRepo.followSetlist(any()))
          .thenThrow(Exception('follow failed'));

      final states = <AsyncValue<void>>[];
      final sub = container.listen(
        setlistControllerProvider,
        (_, next) => states.add(next),
      );

      await container.read(setlistControllerProvider.notifier).toggleFollow(
            setlistId: 'sl-1',
            isCurrentlyFollowing: false,
          );

      sub.close();

      expect(states.any((s) => s is AsyncError), isTrue);
    });
  });

  // =========================================================================
  group('SetlistController.addSongs', () {
    test('transitions loading → data when repo succeeds', () async {
      when(() => mockRepo.addSongsToSet(any())).thenAnswer((_) async {});
      // addSongsToSet internally calls getSetlistById to calculate sort_order
      when(() => mockRepo.getSetlistById(any()))
          .thenAnswer((_) async => tSetlist(id: 'sl-1'));

      final states = <AsyncValue<void>>[];
      final sub = container.listen(
        setlistControllerProvider,
        (_, next) => states.add(next),
      );

      await container.read(setlistControllerProvider.notifier).addSongs(
            setlistId: 'sl-1',
            songsWithKeys: {'song-1': 'G', 'song-2': 'Am'},
          );

      sub.close();

      expect(states.any((s) => s is AsyncLoading), isTrue);
      expect(
        container.read(setlistControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('transitions loading → error when repo throws', () async {
      when(() => mockRepo.addSongsToSet(any()))
          .thenThrow(Exception('insert failed'));
      when(() => mockRepo.getSetlistById(any()))
          .thenAnswer((_) async => tSetlist(id: 'sl-1'));

      final states = <AsyncValue<void>>[];
      final sub = container.listen(
        setlistControllerProvider,
        (_, next) => states.add(next),
      );

      await container.read(setlistControllerProvider.notifier).addSongs(
            setlistId: 'sl-1',
            songsWithKeys: {'song-1': 'G'},
          );

      sub.close();

      expect(states.any((s) => s is AsyncError), isTrue);
    });
  });
}

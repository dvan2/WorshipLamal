import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worship_lamal/features/setlists/data/models/setlist_model.dart';
import 'package:worship_lamal/features/setlists/data/remote/setlists_api.dart';
import 'package:worship_lamal/features/setlists/data/repositories/setlist_repository.dart';

import '../test_utils/fakes/fixtures.dart';

// 1. Create a Mock for the API
class MockSetlistsApi extends Mock implements SetlistsApi {}

// 2. Define fake data helpers

void main() {
  late SetlistRepository repository;
  late MockSetlistsApi mockApi;

  setUp(() {
    mockApi = MockSetlistsApi();
    repository = SetlistRepository(mockApi);

    // Register fallback values for arguments mocktail hasn't seen before
    registerFallbackValue(<Map<String, dynamic>>[]);
    when(
      () => mockApi.deleteAndNormalize(any(), any()),
    ).thenAnswer((_) async {});
  });

  group('SetlistRepository Logic Tests', () {
    // --- TEST 1: ADD SONGS (Checking Sort Order Logic) ---
    test(
      'addSongsToSet calculates correct sort_order (Avoiding Collisions)',
      () async {
        final setlistId = 'set_123';

        final existingItems = [
          SetlistItem(id: 'i1', songId: 's1', sortOrder: 0, song: fakeSong),
          SetlistItem(
            id: 'i2',
            songId: 's2',
            sortOrder: 5,
            song: fakeSong,
          ), // High number!
        ];

        final mockSetlist = Setlist(
          id: setlistId,
          items: existingItems,
          title: 'Test',
          userId: 'u1',
          createdAt: DateTime.now(),
          isPublic: false,
        );

        when(
          () => mockApi.fetchSetlistById(setlistId),
        ).thenAnswer((_) async => mockSetlist);

        when(() => mockApi.addSetlistItems(any())).thenAnswer((_) async {});

        // ACT: Add a new song
        await repository.addSongsToSet([
          {'setlist_id': setlistId, 'song_id': 'new_song', 'key': 'C'},
        ]);

        final capturedCall =
            verify(() => mockApi.addSetlistItems(captureAny())).captured.single
                as List<Map<String, dynamic>>;

        expect(
          capturedCall.first['sort_order'],
          6,
          reason:
              "New item should be placed after the highest existing order (5 + 1 = 6)",
        );
      },
    );

    test('removeSong calls the atomic DB function', () async {
      final setlistId = 'set_123';
      final itemIdToDelete = 'item_to_delete';

      // 1. Stub the RPC call
      when(
        () => mockApi.deleteAndNormalize(any(), any()),
      ).thenAnswer((_) async {});

      // 2. Act
      await repository.removeSong(setlistId, itemIdToDelete);

      // 3. Assert
      // We no longer check for manual updates or loops.
      // We just verify the repository delegated the work to the DB.
      verify(
        () => mockApi.deleteAndNormalize(itemIdToDelete, setlistId),
      ).called(1);
    });

    // --- TEST 3: REORDER (Mapping Logic) ---
    test(
      'reorderSetlistItems maps model list to update payload correctly',
      () async {
        final items = [
          SetlistItem(
            id: 'i1',
            songId: 's1',
            sortOrder: 99,
            song: fakeSong,
          ), // 99 is wrong, we want index
          SetlistItem(id: 'i2', songId: 's2', sortOrder: 88, song: fakeSong),
        ];

        when(() => mockApi.updateSetlistOrder(any())).thenAnswer((_) async {});

        // ACT
        await repository.reorderSetlistItems('set_1', items);

        // ASSERT
        final captured =
            verify(
                  () => mockApi.updateSetlistOrder(captureAny()),
                ).captured.single
                as List<Map<String, dynamic>>;

        // Check Item 1
        expect(captured[0]['id'], 'i1');
        expect(
          captured[0]['sort_order'],
          0,
          reason: "First item in list must get order 0",
        );

        // Check Item 2
        expect(captured[1]['id'], 'i2');
        expect(
          captured[1]['sort_order'],
          1,
          reason: "Second item in list must get order 1",
        );
      },
    );
  });
}

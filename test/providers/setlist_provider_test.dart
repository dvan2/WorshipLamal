import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart';
import '../test_utils/fakes/fake_setlist_repository.dart';
import '../test_utils/fakes/fake_song_repository.dart';

void main() {
  late FakeSetlistRepository fakeRepo;
  late ProviderContainer container;
  late FakeSongRepository fakeSongRepo;

  setUp(() {
    fakeRepo = FakeSetlistRepository();
    fakeSongRepo = FakeSongRepository();

    container = ProviderContainer(
      overrides: [
        setlistRepositoryProvider.overrideWithValue(fakeRepo),
        songRepositoryProvider.overrideWithValue(fakeSongRepo),
        preferencesProvider.overrideWith(() => (MockPreferencesNotifier())),
      ],
    );
  });

  test('createSetlist adds a real item to the fake database', () async {
    final controller = container.read(setlistControllerProvider.notifier);

    // 1. Create
    final newId = await controller.createSetlist('Morning Worship');

    // 2. Verify it exists in the "DB"
    final setlists = await fakeRepo.getSetlists();
    expect(setlists.length, 1);
    expect(setlists.first.id, newId);
    expect(setlists.first.title, 'Morning Worship');
  });

  test('addSong updates the setlist in memory', () async {
    // 1. Setup: Create a setlist first
    final setlistId = await fakeRepo.createSetlist('Test Set');

    // 2. Act: Add a song
    final controller = container.read(setlistControllerProvider.notifier);
    await controller.addSongs(setlistId: setlistId, songIds: ['song_1']);

    // 3. Assert: Fetch the specific setlist and check items
    final setlist = await fakeRepo.getSetlistById(setlistId);
    expect(setlist.items.length, 1);
    expect(setlist.items.first.songId, 'song_1');
  });

  test('Ownership Check: Users only own setlists they created', () async {
    // SCENARIO 1: User A creates a setlist
    fakeRepo.mockCurrentUserId = 'user_A'; // Log in as User A
    final setlistidA = await fakeRepo.createSetlist('User A Service');

    // SCENARIO 2: User B creates a setlist
    fakeRepo.mockCurrentUserId = 'user_B'; // Log in as User B
    final setlistidB = await fakeRepo.createSetlist('User B Service');

    // ASSERTIONS
    // Fetch both lists
    final setlistA = await fakeRepo.getSetlistById(setlistidA);
    final setlistB = await fakeRepo.getSetlistById(setlistidB);

    // TEST: Logic for User A
    const currentUser = 'user_A';

    // 1. Verify User A owns their own list
    expect(
      setlistA.userId == currentUser,
      isTrue,
      reason: "User A should own list A",
    );

    // 2. Verify User A does NOT own User B's list
    expect(
      setlistB.userId == currentUser,
      isFalse,
      reason: "User A should NOT own list B",
    );

    // 3. Validate stored IDs match exact expectations
    expect(setlistA.userId, 'user_A');
    expect(setlistB.userId, 'user_B');
  });

  test('Security Check: Non-owner cannot delete songs', () async {
    // 1. Setup: User A creates a setlist with one song
    fakeRepo.mockCurrentUserId = 'user_A';
    final setlistId = await fakeRepo.createSetlist('User A List');
    await fakeRepo.addSong(setlistId: setlistId, songId: 'song_1', order: 0);

    // Fetch the item ID (needed for deletion)
    var setlist = await fakeRepo.getSetlistById(setlistId);
    final itemId = setlist.items.first.id;

    // 2. Act: Switch to User B (The "Hacker" or Guest)
    fakeRepo.mockCurrentUserId = 'user_B';

    // 3. Assert: Attempting to delete should throw an exception
    expect(
      () async => await fakeRepo.removeSong(setlist.id, itemId),
      throwsA(isA<Exception>()),
      reason: "User B should NOT be able to delete User A's song",
    );

    // 4. Verify: The song should still exist in the database
    setlist = await fakeRepo.getSetlistById(setlistId);
    expect(
      setlist.items.length,
      1,
      reason: "The song should still remain in the list",
    );
  });

  test(
    'Vocal Mode: Adding song in Female Mode auto-transposes key (-5)',
    () async {
      // 1. Setup: Switch to Female Mode
      final prefsNotifier =
          container.read(preferencesProvider.notifier)
              as MockPreferencesNotifier;
      prefsNotifier.setMode(VocalMode.female);

      // Setup: Ensure the Fake Song Repo returns a song with a known key
      // (Assuming FakeSongRepository returns a song with key 'C' by default)
      // C transposed -5 semitones -> G

      final setlistId = await fakeRepo.createSetlist('Worship Service');

      // 2. Act: Add the song
      final controller = container.read(setlistControllerProvider.notifier);
      await controller.addSongs(
        setlistId: setlistId,
        songIds: ['song_with_key_C'],
      );

      // 3. Assert
      final setlist = await fakeRepo.getSetlistById(setlistId);
      final item = setlist.items.first;

      expect(
        item.keyOverride,
        'G',
        reason: "Key 'C' should transpose to 'G' in female mode",
      );
    },
  );

  test('Batch Add: Can add multiple songs at once', () async {
    final setlistId = await fakeRepo.createSetlist('Batch Test');
    final controller = container.read(setlistControllerProvider.notifier);

    // Act: Add 3 songs
    await controller.addSongs(
      setlistId: setlistId,
      songIds: ['s1', 's2', 's3'],
    );

    // Assert
    final setlist = await fakeRepo.getSetlistById(setlistId);
    expect(setlist.items.length, 3);

    // Check order (0, 1, 2)
    expect(setlist.items[0].songId, 's1');
    expect(setlist.items[0].sortOrder, 0);
    expect(setlist.items[2].songId, 's3');
    expect(setlist.items[2].sortOrder, 2);
  });

  test('Reorder: Updates sort order in database', () async {
    // 1. Setup: Create list with [A, B]
    final setlistId = await fakeRepo.createSetlist('Reorder Test');
    final controller = container.read(setlistControllerProvider.notifier);
    await controller.addSongs(
      setlistId: setlistId,
      songIds: ['song_A', 'song_B'],
    );

    var setlist = await fakeRepo.getSetlistById(setlistId);
    final itemA = setlist.items[0];
    final itemB = setlist.items[1];

    // 2. Act: Swap them in memory and send to controller
    // New Order: [B, A]
    final reorderedList = [itemB, itemA];

    await controller.reorderSongs(
      setlistId: setlistId,
      currentList: reorderedList,
    );

    // 3. Assert: Fetch fresh from DB and check indices
    setlist = await fakeRepo.getSetlistById(setlistId);

    expect(
      setlist.items[0].songId,
      'song_B',
      reason: "First item should now be B",
    );
    expect(
      setlist.items[1].songId,
      'song_A',
      reason: "Second item should now be A",
    );
  });

  test('Update Key Override: Persists new key', () async {
    // 1. Setup
    final setlistId = await fakeRepo.createSetlist('Key Test');
    final controller = container.read(setlistControllerProvider.notifier);
    await controller.addSongs(setlistId: setlistId, songIds: ['song_1']);

    var setlist = await fakeRepo.getSetlistById(setlistId);
    final itemId = setlist.items.first.id;

    // 2. Act: Change key to 'F#'
    await controller.updateKeyOverride(
      setlistId: setlistId,
      itemId: itemId,
      newKey: 'F#',
    );

    setlist = await fakeRepo.getSetlistById(setlistId);
    expect(setlist.items.first.keyOverride, 'F#');
  });

  test('Remove Song: Deletes item and updates count', () async {
    // 1. Setup
    final setlistId = await fakeRepo.createSetlist('Delete Test');
    final controller = container.read(setlistControllerProvider.notifier);
    await controller.addSongs(
      setlistId: setlistId,
      songIds: ['song_to_delete'],
    );

    var setlist = await fakeRepo.getSetlistById(setlistId);
    final item = setlist.items.first;

    // 2. Act
    await controller.removeSong(setlistId: setlistId, item: item);

    // 3. Assert
    setlist = await fakeRepo.getSetlistById(setlistId);
    expect(setlist.items.isEmpty, isTrue);
  });

  test('Toggle Follow: correctly follows and unfollows setlists', () async {
    // 1. Setup: Create a setlist
    final setlistId = await fakeRepo.createSetlist('Community Worship');
    final controller = container.read(setlistControllerProvider.notifier);

    // -------------------------------------------------------------
    // SCENARIO 1: Follow (currently NOT following)
    // -------------------------------------------------------------

    // Act
    await controller.toggleFollow(
      setlistId: setlistId,
      isCurrentlyFollowing: false,
    );

    // Assert
    var isFollowing = await fakeRepo.isFollowing(setlistId);
    expect(isFollowing, isTrue, reason: "Should be following after toggle ON");

    // Optional: Check if it appears in the followed list
    var followedList = await fakeRepo.getFollowedSetlists();
    expect(followedList.length, 1);

    // -------------------------------------------------------------
    // SCENARIO 2: Unfollow (currently IS following)
    // -------------------------------------------------------------

    // Act
    await controller.toggleFollow(
      setlistId: setlistId,
      isCurrentlyFollowing: true, // User IS currently following
    );

    // Assert
    isFollowing = await fakeRepo.isFollowing(setlistId);
    expect(
      isFollowing,
      isFalse,
      reason: "Should NOT be following after toggle OFF",
    );

    followedList = await fakeRepo.getFollowedSetlists();
    expect(followedList.isEmpty, isTrue);
  });
}

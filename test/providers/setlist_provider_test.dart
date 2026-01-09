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
}

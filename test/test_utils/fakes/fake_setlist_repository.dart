import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/songs/data/repositories/setlist_repository.dart';

import 'fixtures.dart';

class FakeSetlistRepository implements SetlistRepository {
  final List<Setlist> _setlists = [];
  String mockCurrentUserId = 'user_1';

  FakeSetlistRepository({List<Setlist>? initialData}) {
    if (initialData != null) _setlists.addAll(initialData);
  }

  @override
  Future<List<Setlist>> getSetlists() async {
    return _setlists;
  }

  @override
  Future<Setlist> getSetlistById(String id) async {
    return _setlists.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('Setlist not found'),
    );
  }

  @override
  Future<String> createSetlist(String title) async {
    final newId = 'setlist_${_setlists.length + 1}';
    final newSetlist = Setlist(
      id: newId,
      title: title,
      userId: mockCurrentUserId, // Default fake user
      createdAt: DateTime.now(),
      isPublic: false,
      items: [],
    );
    _setlists.add(newSetlist);
    return newId;
  }

  @override
  Future<void> addSong({
    required String setlistId,
    required String songId,
    required int order,
    String? keyOverride,
  }) async {
    final index = _setlists.indexWhere((s) => s.id == setlistId);
    if (index == -1) throw Exception('Setlist not found');

    final setlist = _setlists[index];

    // Create a Fake SetlistItem
    // NOTE: In a real app, the DB fetches the Song details via join.
    // In a fake, we must construct a dummy Song object or fetch from FakeSongRepo.
    // For simplicity here, we create a minimal dummy song.
    final newItem = SetlistItem(
      id: 'item_${setlist.items.length + 1}',
      songId: songId,
      sortOrder: order,
      song: fakeSong,
    );

    // Update the setlist with the new item
    // We have to replace the setlist object since it might be immutable
    final updatedItems = List<SetlistItem>.from(setlist.items)..add(newItem);

    _setlists[index] = Setlist(
      id: setlist.id,
      title: setlist.title,
      userId: setlist.userId,
      createdAt: setlist.createdAt,
      isPublic: setlist.isPublic,
      items: updatedItems,
    );
  }

  @override
  Future<void> removeSong(String itemId) async {
    for (var i = 0; i < _setlists.length; i++) {
      final setlist = _setlists[i];

      // Found the setlist containing the item
      if (setlist.items.any((item) => item.id == itemId)) {
        // 👇 NEW: RLS Simulation check
        if (setlist.userId != mockCurrentUserId) {
          throw Exception('Security Error: You do not own this setlist');
        }

        final updatedItems = setlist.items
            .where((item) => item.id != itemId)
            .toList();

        _setlists[i] = Setlist(
          id: setlist.id,
          title: setlist.title,
          userId: setlist.userId,
          createdAt: setlist.createdAt,
          isPublic: setlist.isPublic,
          items: updatedItems,
        );
        return;
      }
    }
  }

  @override
  Future<void> reorderSetlistItems(
    String setlistId,
    List<SetlistItem> items,
  ) async {
    final index = _setlists.indexWhere((s) => s.id == setlistId);
    if (index == -1) throw Exception('Setlist not found');

    // Just replace the items list with the new reordered list passed from Controller
    _setlists[index] = Setlist(
      id: _setlists[index].id,
      title: _setlists[index].title,
      userId: _setlists[index].userId,
      createdAt: _setlists[index].createdAt,
      isPublic: _setlists[index].isPublic,
      items: items,
    );
  }

  @override
  Future<void> updateKeyOverride(String itemId, String newKey) async {
    // Logic to find item and update keyOverride field...
    // (Omitted for brevity, but follows same pattern as add/remove)
  }

  @override
  Future<void> updateSetlistPublicStatus(
    String setlistId,
    bool isPublic,
  ) async {
    final index = _setlists.indexWhere((s) => s.id == setlistId);
    if (index != -1) {
      // Copy with new status
    }
  }

  @override
  Future<void> followSetlist(String setlistId) {
    // TODO: implement followSetlist
    throw UnimplementedError();
  }

  @override
  Future<List<Setlist>> getFollowedSetlists() {
    // TODO: implement getFollowedSetlists
    throw UnimplementedError();
  }

  @override
  Future<bool> isFollowing(String setlistId) {
    // TODO: implement isFollowing
    throw UnimplementedError();
  }

  @override
  Future<void> unfollowSetlist(String setlistId) {
    // TODO: implement unfollowSetlist
    throw UnimplementedError();
  }

  @override
  Future<void> addSetlistItems(List<Map<String, dynamic>> rawItems) {
    // TODO: implement addSetlistItems
    throw UnimplementedError();
  }
}

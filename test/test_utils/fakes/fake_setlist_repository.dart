import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/songs/data/repositories/setlist_repository.dart';

import 'fixtures.dart';

class FakeSetlistRepository implements SetlistRepository {
  final List<Setlist> _setlists = [];
  String mockCurrentUserId = 'user_1';
  final Set<String> _followedSetlistIds = {};

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
      userId: mockCurrentUserId,
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

    final newItem = SetlistItem(
      id: 'item_${setlist.items.length + 1}',
      songId: songId,
      sortOrder: order,
      song: fakeSong,
    );

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
  Future<void> removeSong(String setlistId, String itemId) async {
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
    // 1. Iterate through all setlists to find the one containing the item
    for (int i = 0; i < _setlists.length; i++) {
      final setlist = _setlists[i];
      final itemIndex = setlist.items.indexWhere((item) => item.id == itemId);

      // 2. If found, update it
      if (itemIndex != -1) {
        // Create a copy of the item with the new key
        final updatedItem = setlist.items[itemIndex].copyWith(
          keyOverride: newKey,
        );

        // Create a new list of items with the updated item inserted
        final updatedItems = List<SetlistItem>.from(setlist.items);
        updatedItems[itemIndex] = updatedItem;

        // Save the updated setlist back to memory
        _setlists[i] = setlist.copyWith(items: updatedItems);
        return; // Exit once found and updated
      }
    }

    throw Exception('Item with ID $itemId not found');
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
  Future<void> followSetlist(String setlistId) async {
    // Simulate API delay if you want, or just add immediately
    _followedSetlistIds.add(setlistId);
  }

  @override
  Future<void> unfollowSetlist(String setlistId) async {
    _followedSetlistIds.remove(setlistId);
  }

  @override
  Future<bool> isFollowing(String setlistId) async {
    return _followedSetlistIds.contains(setlistId);
  }

  @override
  Future<List<Setlist>> getFollowedSetlists() async {
    return _setlists.where((s) => _followedSetlistIds.contains(s.id)).toList();
  }

  @override
  Future<void> addSongsToSet(List<Map<String, dynamic>> rawItems) async {
    if (rawItems.isEmpty) return;

    final setlistId = rawItems.first['setlist_id'] as String;

    // 1. Find the Setlist in memory
    final index = _setlists.indexWhere((s) => s.id == setlistId);
    if (index == -1) {
      throw Exception('Setlist not found for id: $setlistId');
    }
    final currentSetlist = _setlists[index];

    // 2. Determine the starting Sort Order
    // (Matches the "Max + 1" logic we discussed to handle gaps correctly)
    int nextOrderIndex = 0;
    if (currentSetlist.items.isNotEmpty) {
      final maxOrder = currentSetlist.items
          .map((item) => item.sortOrder)
          .reduce((curr, next) => curr > next ? curr : next);
      nextOrderIndex = maxOrder + 1;
    }

    // 3. Convert Raw Maps to Real SetlistItems
    final newItems = <SetlistItem>[];

    for (final item in rawItems) {
      final songId = item['song_id'];
      final keyOverride =
          item['key'] ?? item['key_override']; // Handle both keys

      newItems.add(
        SetlistItem(
          // Generate a unique-ish ID for the fake item
          id: 'item_${setlistId}_${nextOrderIndex}_$songId',
          songId: songId,
          sortOrder: nextOrderIndex++, // Increment for next item
          keyOverride: keyOverride,
          song: fakeSong, // Uses the global 'fakeSong' from fixtures.dart
        ),
      );
    }

    // 4. Update the Fake Database
    // Create a new Setlist object with the combined list of items
    final updatedList = List<SetlistItem>.from(currentSetlist.items)
      ..addAll(newItems);

    _setlists[index] = currentSetlist.copyWith(items: updatedList);
  }

  // NOTE: If your interface also defines 'addSetlistItems',
  // you can alias it to this method or implement it similarly.
  Future<void> addSetlistItems(List<Map<String, dynamic>> items) async {
    await addSongsToSet(items);
  }
}

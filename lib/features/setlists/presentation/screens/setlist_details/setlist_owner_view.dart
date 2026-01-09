import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/key_picker_dialog.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/item_card.dart';

// 1. Change to ConsumerStatefulWidget
class SetlistOwnerView extends ConsumerStatefulWidget {
  final Setlist setlist;
  const SetlistOwnerView({super.key, required this.setlist});

  @override
  ConsumerState<SetlistOwnerView> createState() => _SetlistOwnerViewState();
}

class _SetlistOwnerViewState extends ConsumerState<SetlistOwnerView> {
  // 2. Local Mutable List (The key to 0ms latency)
  late List<SetlistItem> _items;

  @override
  void initState() {
    super.initState();
    // Initialize local list from the source of truth
    _items = List.from(widget.setlist.items);
  }

  @override
  void didUpdateWidget(SetlistOwnerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with Server: If database updates (e.g. pull-to-refresh), update local list
    if (widget.setlist.items != oldWidget.setlist.items) {
      _items = List.from(widget.setlist.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _items.length, // USE LOCAL LIST
      buildDefaultDragHandles: false,
      onReorder: _onReorder, // Extracted logic below
      itemBuilder: (context, index) {
        final item = _items[index]; // USE LOCAL LIST

        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          onDismissed: (_) => _handleRemove(context, ref, item, index),
          child: SetlistItemCard(
            item: item,
            index: index,
            onTap: () => context.pushNamed(
              'songDetail',
              pathParameters: {'id': item.songId},
            ),
            onKeyTap: () => _showKeyPicker(context, ref, item),
          ),
        );
      },
    );
  }

  // 3. The Logic Connection
  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // A. INSTANT UI UPDATE
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    ref
        .read(setlistControllerProvider.notifier)
        .reorderSongs(setlistId: widget.setlist.id, currentList: _items);
  }

  void _handleRemove(
    BuildContext context,
    WidgetRef ref,
    SetlistItem item,
    int index,
  ) {
    // Optimistic Remove
    setState(() {
      _items.removeAt(index);
    });

    final controller = ref.read(setlistControllerProvider.notifier);
    controller.removeSong(setlistId: widget.setlist.id, item: item);

    ScaffoldMessenger.of(context).clearSnackBars();
    final snackBarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${item.song.title}"'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Optimistic Undo
            setState(() {
              _items.insert(index, item);
            });
          },
        ),
      ),
    );

    snackBarController.closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        ref
            .read(setlistControllerProvider.notifier)
            .removeSong(setlistId: widget.setlist.id, item: item);
      }
    });
  }

  void _showKeyPicker(BuildContext context, WidgetRef ref, SetlistItem item) {
    showDialog(
      context: context,
      builder: (context) => KeyPickerDialog(
        currentKey: item.displayKey,
        onKeySelected: (newKey) {
          // 1. Update Database
          ref
              .read(setlistControllerProvider.notifier)
              .updateKeyOverride(
                setlistId: widget.setlist.id,
                itemId: item.id,
                newKey: newKey,
              );

          // 2. Optimistic Update (Optional, requires copyWith)
          setState(() {
            final idx = _items.indexWhere((i) => i.id == item.id);
            if (idx != -1) {
              _items[idx] = _items[idx].copyWith(keyOverride: newKey);
            }
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Key changed to $newKey')));
        },
      ),
    );
  }
}

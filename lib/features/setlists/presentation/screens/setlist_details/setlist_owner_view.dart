import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/key_picker_dialog.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/item_card.dart';

class SetlistOwnerView extends ConsumerWidget {
  final Setlist setlist;
  const SetlistOwnerView({super.key, required this.setlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: setlist.items.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        ref
            .read(setlistControllerProvider.notifier)
            .reorderSongs(
              setlistId: setlist.id,
              currentList: setlist.items,
              oldIndex: oldIndex,
              newIndex: newIndex,
            );
      },
      itemBuilder: (context, index) {
        final item = setlist.items[index];
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
          onDismissed: (_) => _handleRemove(context, ref, item),
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

  void _handleRemove(BuildContext context, WidgetRef ref, SetlistItem item) {
    final controller = ref.read(setlistControllerProvider.notifier);
    controller.removeSong(setlistId: setlist.id, item: item);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${item.song.title}"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () =>
              controller.undoRemove(setlistId: setlist.id, item: item),
        ),
      ),
    );
  }

  void _showKeyPicker(BuildContext context, WidgetRef ref, SetlistItem item) {
    showDialog(
      context: context,
      builder: (context) => KeyPickerDialog(
        currentKey: item.displayKey,
        onKeySelected: (newKey) {
          ref
              .read(setlistControllerProvider.notifier)
              .updateKeyOverride(
                setlistId: setlist.id,
                itemId: item.id,
                newKey: newKey,
              );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Key changed to $newKey')));
        },
      ),
    );
  }
}

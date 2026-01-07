import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/item_card.dart';

class SetlistViewerView extends StatelessWidget {
  final Setlist setlist;
  const SetlistViewerView({super.key, required this.setlist});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: setlist.items.length,
      itemBuilder: (context, index) {
        final item = setlist.items[index];
        return SetlistItemCard(
          item: item,
          index: index,
          showDragHandle: false, // Hide drag handle
          onTap: () => context.pushNamed(
            'songDetail',
            pathParameters: {'id': item.songId},
          ),
          onKeyTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Only the owner can change keys.")),
            );
          },
        );
      },
    );
  }
}

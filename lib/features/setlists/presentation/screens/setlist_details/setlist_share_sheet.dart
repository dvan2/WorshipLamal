import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';

// Helper function to show the sheet
void showSetlistShareSheet(
  BuildContext context,
  WidgetRef ref,
  Setlist setlist,
) {
  final link = "worship-lamal-f1b1c.web.app/setlist/${setlist.id}";

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            setlist.isPublic ? "Share Setlist" : "Make Public & Share?",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (!setlist.isPublic)
            _buildMakePublicSection(context, ref, setlist, link)
          else
            _buildAlreadyPublicSection(context, ref, setlist, link),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Widget _buildMakePublicSection(
  BuildContext context,
  WidgetRef ref,
  Setlist setlist,
  String link,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "To share this setlist, it must be made Public (view-only).",
        style: TextStyle(color: Colors.grey),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.public),
          label: const Text("Make Public & Copy Link"),
          onPressed: () async {
            // 1. Update DB
            final repo = ref.read(setlistRepositoryProvider);
            await repo.updateSetlistPublicStatus(setlist.id, true);

            // 2. Copy & Close
            await Clipboard.setData(ClipboardData(text: link));
            ref.invalidate(setlistDetailProvider(setlist.id));

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Link copied! Setlist is now Public."),
                ),
              );
            }
          },
        ),
      ),
    ],
  );
}

Widget _buildAlreadyPublicSection(
  BuildContext context,
  WidgetRef ref,
  Setlist setlist,
  String link,
) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(link, overflow: TextOverflow.ellipsis)),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Link copied!")));
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      TextButton(
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        onPressed: () async {
          final repo = ref.read(setlistRepositoryProvider);
          await repo.updateSetlistPublicStatus(setlist.id, false);
          ref.invalidate(setlistDetailProvider(setlist.id));

          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Setlist is now Private.")),
            );
          }
        },
        child: const Text("Stop Sharing (Make Private)"),
      ),
    ],
  );
}

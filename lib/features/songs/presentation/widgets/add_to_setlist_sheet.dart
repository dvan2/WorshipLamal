import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';

class AddToSetlistSheet extends ConsumerWidget {
  final String songId;
  final String songTitle;

  const AddToSetlistSheet({
    super.key,
    required this.songId,
    required this.songTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the user's setlists
    final setlistsAsync = ref.watch(setlistsListProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Add '$songTitle' to...",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),

          // List of Setlists
          setlistsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(child: Text("Error loading setlists")),
            data: (setlists) {
              if (setlists.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text("No setlists found. Create one first!"),
                  ),
                );
              }

              return Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: setlists.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final setlist = setlists[index];
                    final isAlreadyInSet = setlist.items.any(
                      (item) => item.songId == songId,
                    );
                    return ListTile(
                      leading: Icon(
                        isAlreadyInSet ? Icons.check_circle : Icons.queue_music,
                      ),
                      title: Text(
                        setlist.title,
                        style: TextStyle(
                          color: isAlreadyInSet ? Colors.grey : Colors.black,
                          decoration: isAlreadyInSet
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        isAlreadyInSet
                            ? "Already added"
                            : "${setlist.items.length} songs",
                        style: TextStyle(
                          color: isAlreadyInSet ? Colors.grey : null,
                        ),
                      ),

                      enabled: !isAlreadyInSet,
                      onTap: isAlreadyInSet
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);

                              context.pop();

                              try {
                                await ref
                                    .read(setlistControllerProvider.notifier)
                                    .addSong(
                                      setlistId: setlist.id,
                                      songId: songId,
                                    );

                                // 3. Show Success Message
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Added '$songTitle' to ${setlist.title}",
                                    ),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Failed to add song: $e"),
                                    ),
                                  );
                                }
                              }
                            },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

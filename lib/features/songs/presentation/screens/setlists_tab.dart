import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/presentation/providers/setlist_provider.dart';

class SetlistsTab extends ConsumerWidget {
  const SetlistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the list of setlists
    final setlistsAsync = ref.watch(setlistsListProvider);

    return Scaffold(
      // The "+" Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () => _showCreateDialog(context),
      ),
      body: setlistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (setlists) {
          if (setlists.isEmpty) {
            return _EmptySetlistState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: setlists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final setlist = setlists[index];
              return Card(
                elevation: 0,
                color: AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    setlist.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${setlist.items.length} songs • ${_formatDate(setlist.createdAt)}',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Navigate to details (Ensure this route exists in your router)
                    context.pushNamed(
                      'setlistDetail',
                      pathParameters: {'id': setlist.id},
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper to show the dialog
  void _showCreateDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _CreateSetlistDialog());
  }

  String _formatDate(DateTime date) {
    // Simple formatter. You can use intl package later if needed.
    return "${date.day}/${date.month}/${date.year}";
  }
}

class _EmptySetlistState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            "No setlists yet",
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text("Tap the + button to create one"),
        ],
      ),
    );
  }
}

// The Dialog to Create a Setlist
class _CreateSetlistDialog extends ConsumerStatefulWidget {
  const _CreateSetlistDialog();

  @override
  ConsumerState<_CreateSetlistDialog> createState() =>
      __CreateSetlistDialogState();
}

class __CreateSetlistDialogState extends ConsumerState<_CreateSetlistDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Watch controller state to show spinner if loading
    final state = ref.watch(setlistControllerProvider);
    final isLoading = state.isLoading;

    return AlertDialog(
      title: const Text('New Setlist'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'e.g. Sunday Service Oct 22',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  if (_controller.text.trim().isEmpty) return;

                  // Call the controller
                  final newId = await ref
                      .read(setlistControllerProvider.notifier)
                      .createSetlist(_controller.text.trim());

                  if (newId != null && context.mounted) {
                    Navigator.pop(context); // Close dialog

                    // Optional: Navigate directly to the new setlist
                    // context.pushNamed('setlistDetail', pathParameters: {'id': newId});
                  }
                },
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

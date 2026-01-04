import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';

class CreateSetlistDialog extends ConsumerStatefulWidget {
  const CreateSetlistDialog({super.key});

  @override
  ConsumerState<CreateSetlistDialog> createState() =>
      _CreateSetlistDialogState();
}

class _CreateSetlistDialogState extends ConsumerState<CreateSetlistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        enabled: !isLoading, // Disable input while loading
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
                    // Optional: You could navigate to the new list here
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

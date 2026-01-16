import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/key_picker_dialog.dart';
import 'package:worship_lamal/features/userkey/presentation/providers/user_keys_provider.dart';

class ChordViewToolbar extends ConsumerWidget {
  final String songId;
  final String originalKey;

  const ChordViewToolbar({
    super.key,
    required this.songId,
    required this.originalKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the user's preferred key for this specific song
    final userKeysMap = ref.watch(userPreferredKeysMapProvider);
    final userPreferredKey = userKeysMap[songId];

    // 2. Determine what to show
    final currentDisplayKey = userPreferredKey ?? originalKey;
    final isCustom = userPreferredKey != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // CONTROL 1: Key Selector
          Expanded(
            child: InkWell(
              onTap: () => _showKeyPicker(context, ref, userPreferredKey),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isCustom
                      ? Colors.deepOrange.withOpacity(0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: isCustom
                      ? Border.all(color: Colors.deepOrange, width: 1)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KEY",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCustom ? Colors.deepOrange : Colors.grey,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          currentDisplayKey,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isCustom ? Colors.deepOrange : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // CONTROL 2: Nashville Toggle (Placeholder for now)
          // Good UX: Quick toggle to see numbers instead of letters
          _buildToolButton(
            icon: Icons.numbers,
            label: "1-4-5",
            onTap: () {
              // TODO: Connect to a state provider later
            },
          ),

          const SizedBox(width: 8),

          // CONTROL 3: Text Size (Crucial for musicians)
          _buildToolButton(
            icon: Icons.text_fields,
            label: "Size",
            onTap: () {
              // TODO: Connect to font size provider
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [Icon(icon, size: 20)]),
      ),
    );
  }

  void _showKeyPicker(BuildContext context, WidgetRef ref, String? currentKey) {
    showDialog(
      context: context,
      builder: (context) => KeyPickerDialog(
        currentKey: currentKey,
        onKeySelected: (key) {
          ref.read(userKeyControllerProvider.notifier).setKey(songId, key);
        },
        onReset: () {
          ref.read(userKeyControllerProvider.notifier).revertKey(songId);
        },
      ),
    );
  }
}

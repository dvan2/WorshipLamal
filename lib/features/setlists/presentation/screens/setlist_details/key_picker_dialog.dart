// lib/features/songs/presentation/widgets/key_picker_dialog.dart

import 'package:flutter/material.dart';

class KeyPickerDialog extends StatelessWidget {
  final String? currentKey; // Nullable if no key is selected
  final Function(String) onKeySelected;
  final VoidCallback? onReset; // New callback for resetting

  const KeyPickerDialog({
    super.key,
    required this.currentKey,
    required this.onKeySelected,
    this.onReset,
  });

  static const _keys = [
    'C',
    'C#',
    'D',
    'Eb',
    'E',
    'F',
    'F#',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Key'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _keys.map((key) {
          return ChoiceChip(
            label: Text(key),
            selected: key == currentKey,
            onSelected: (selected) {
              if (selected) {
                onKeySelected(key);
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
      actions: [
        // Only show Reset if a reset callback is provided AND we have a current custom key
        if (onReset != null && currentKey != null)
          TextButton(
            onPressed: () {
              onReset!();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset to Original'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class KeyPickerDialog extends StatelessWidget {
  final String currentKey;
  final Function(String) onKeySelected;

  const KeyPickerDialog({
    super.key,
    required this.currentKey,
    required this.onKeySelected,
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

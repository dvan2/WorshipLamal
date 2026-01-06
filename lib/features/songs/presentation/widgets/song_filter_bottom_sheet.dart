import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/data/models/song_sort_option.dart';
import '../providers/song_filter_provider.dart';

class SongFilterBottomSheet extends ConsumerStatefulWidget {
  const SongFilterBottomSheet({super.key});

  @override
  ConsumerState<SongFilterBottomSheet> createState() =>
      _SongFilterBottomSheetState();
}

class _SongFilterBottomSheetState extends ConsumerState<SongFilterBottomSheet> {
  static const List<String> allKeys = [
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

  // 1. LOCAL STATE (Temporary)
  late Set<String> _tempSelectedKeys;
  late RangeValues _tempBpmRange;
  late SongSortOption _tempSortOption;

  @override
  void initState() {
    super.initState();
    // 2. Initialize with the CURRENT global filters
    final globalState = ref.read(songFilterProvider);
    _tempSelectedKeys = Set.from(globalState.selectedKeys);
    _tempBpmRange = globalState.bpmRange;
    _tempSortOption = globalState.sortOption;
  }

  void _toggleKey(String key) {
    setState(() {
      if (_tempSelectedKeys.contains(key)) {
        _tempSelectedKeys.remove(key);
      } else {
        _tempSelectedKeys.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filter & Sort",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Reset Local State Only
                  setState(() {
                    _tempSelectedKeys = {};
                    _tempBpmRange = const RangeValues(40, 200);
                    _tempSortOption = SongSortOption.titleAz;
                  });
                },
                child: const Text("Reset"),
              ),
            ],
          ),
          const Divider(),

          //Sorting
          const SizedBox(height: 16),
          const Text("Sort By", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 0, // Tighter vertical spacing
            children: SongSortOption.values.map((option) {
              final isSelected = _tempSortOption == option;
              return ChoiceChip(
                label: Text(option.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _tempSortOption = option);
                  }
                },
                // Optional: Custom styling to match your AppColors
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: isSelected
                    ? const BorderSide(color: AppColors.primary)
                    : BorderSide(color: Colors.grey.shade300),
              );
            }).toList(),
          ),

          // --- BPM Filter ---
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "BPM Range",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                "${_tempBpmRange.start.round()} - ${_tempBpmRange.end.round()}",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _tempBpmRange,
            min: 40,
            max: 200,
            divisions: 160,
            activeColor: AppColors.primary,
            labels: RangeLabels(
              _tempBpmRange.start.round().toString(),
              _tempBpmRange.end.round().toString(),
            ),
            onChanged: (values) {
              setState(() => _tempBpmRange = values);
            },
          ),

          // --- Key Filter ---
          const SizedBox(height: 16),
          const Text("Key", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allKeys.map((key) {
              final isSelected = _tempSelectedKeys.contains(key);
              return ChoiceChip(
                label: Text(key),
                selected: isSelected,
                // Update Local State
                onSelected: (_) => _toggleKey(key),
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: isSelected
                    ? const BorderSide(color: AppColors.primary)
                    : BorderSide(color: Colors.grey.shade300),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // --- Show Results Button ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ref
                    .read(songFilterProvider.notifier)
                    .setFilters(
                      selectedKeys: _tempSelectedKeys,
                      bpmRange: _tempBpmRange,
                      sortOption: _tempSortOption,
                    );
                Navigator.pop(context);
              },
              child: const Text(
                "Show Results",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

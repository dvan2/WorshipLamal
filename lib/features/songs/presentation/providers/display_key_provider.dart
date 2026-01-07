import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/utils/key_transposer.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';

// This provider family takes the 'Original Key' and returns the 'Display Key'
final displayKeyProvider = Provider.family<String, String>((ref, originalKey) {
  // 1. Listen to the User's Preference
  final prefs = ref.watch(preferencesProvider);

  // 2. Logic Chain
  if (prefs.vocalMode == VocalMode.female) {
    // Standard Female shift is usually -5 semitones (e.g., G -> D)
    return KeyTransposer.transpose(originalKey, -5);
  }

  // 3. Default: Return original
  return originalKey;
});

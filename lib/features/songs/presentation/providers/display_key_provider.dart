import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/userkey/presentation/providers/user_keys_provider.dart';
import 'package:worship_lamal/core/utils/key_transposer.dart'; // Ensure this exists

// Define a simple record type for the arguments
typedef SongKeyParams = ({String? originalKey, String songId});

final displayKeyProvider = Provider.family<String, SongKeyParams>((
  ref,
  params,
) {
  final originalKey = params.originalKey ?? '';
  final songId = params.songId;

  // 1. PRIORITY 1: User Preferred Key
  // We watch the map so this updates instantly if the user sets a key
  final userKeysMap = ref.watch(userPreferredKeysMapProvider);
  if (userKeysMap.containsKey(songId)) {
    return userKeysMap[songId]!;
  }

  // 2. PRIORITY 2: Transposed (Female Mode)
  // Only applies if there is no user preference
  final prefs = ref.watch(preferencesProvider);
  if (prefs.vocalMode == VocalMode.female && originalKey.isNotEmpty) {
    // Assuming standard female transposition is -5 semitones (adjust as needed)
    return KeyTransposer.transpose(originalKey, -5);
  }

  // 3. PRIORITY 3: Original Key
  return originalKey.isEmpty ? 'Unknown' : originalKey;
});

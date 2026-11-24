import 'music_theory.dart';

class KeyTransposer {
  /// Transposes a key by a set number of semitones.
  /// Example: transpose('G', -5) returns 'D'
  static String transpose(String originalKey, int semitones) {
    if (originalKey.isEmpty) return "";

    // A. Normalize Input (Handle Db vs C#, etc.)
    String key = MusicTheory.normalizeNote(originalKey);

    // B. Find Index
    int index = MusicTheory.chromaticScale.indexOf(key);
    if (index == -1) {
      return originalKey; // Return original if unknown (e.g. "?")
    }

    // C. Calculate New Index (Circular Math)
    // We add 12 before modulo to handle negative subtraction correctly
    int newIndex = (index + semitones) % 12;
    if (newIndex < 0) newIndex += 12;

    return MusicTheory.chromaticScale[newIndex];
  }
}

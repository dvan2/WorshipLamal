class KeyTransposer {
  // 1. Define the Chromatic Scale (Using sharps/flats common in worship)
  static const List<String> _chromaticScale = [
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

  // Map to normalize weird inputs (e.g., if DB has 'Db' but list has 'C#')
  static const Map<String, String> _aliases = {
    'Db': 'C#',
    'D#': 'Eb',
    'Gb': 'F#',
    'G#': 'Ab',
    'A#': 'Bb',
  };

  /// Transposes a key by a set number of semitones.
  /// Example: transpose('G', -5) returns 'D'
  static String transpose(String originalKey, int semitones) {
    if (originalKey.isEmpty) return "";

    // A. Normalize Input (Handle Db vs C#)
    String key = _aliases[originalKey] ?? originalKey;

    // B. Find Index
    int index = _chromaticScale.indexOf(key);
    if (index == -1) {
      return originalKey; // Return original if unknown (e.g. "?")
    }

    // C. Calculate New Index (Circular Math)
    // We add 12 before modulo to handle negative subtraction correctly
    int newIndex = (index + semitones) % 12;
    if (newIndex < 0) newIndex += 12;

    return _chromaticScale[newIndex];
  }
}

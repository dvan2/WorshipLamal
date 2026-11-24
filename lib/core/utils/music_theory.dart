class MusicTheory {
  /// The 12-tone chromatic scale using worship-common enharmonics.
  static const List<String> chromaticScale = [
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

  /// Map to normalize enharmonic inputs to the standard chromatic scale.
  static const Map<String, String> enharmonicAliases = {
    'Cb': 'B',
    'Db': 'C#',
    'D#': 'Eb',
    'Gb': 'F#',
    'G#': 'Ab',
    'A#': 'Bb',
  };

  /// Normalizes a note name by resolving enharmonic aliases.
  static String normalizeNote(String note) {
    return enharmonicAliases[note] ?? note;
  }
}

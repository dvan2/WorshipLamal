class NashvilleHelper {
  // 1. The Chromatic Scale (All 12 notes)
  static const List<String> _notes = [
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

  // 2. The Major Scale Intervals (semitones from root)
  // 1=0, 2=2, 3=4, 4=5, 5=7, 6=9, 7=11
  static const Map<String, int> _intervals = {
    '1': 0,
    '2': 2,
    '3': 4,
    '4': 5,
    '5': 7,
    '6': 9,
    'b7': 10,
    '7': 11,
  };

  static String translate(String nashvilleChord, String keyRoot) {
    if (nashvilleChord.isEmpty) return "";

    String cleanKey = keyRoot.replaceAll('m', '');

    // 1. Add this map to handle Enharmonics
    // This maps the Input (Dropdown) -> To Internal format (Helper List)
    const Map<String, String> normalize = {
      'Cb': 'B',
      'Db': 'C#',
      'D#': 'Eb',
      'Gb': 'F#',
      'G#': 'Ab',
      'A#': 'Bb',
    };

    // 2. Normalize the key if it exists in the map
    if (normalize.containsKey(cleanKey)) {
      cleanKey = normalize[cleanKey]!;
    }

    int keyIndex = _notes.indexOf(cleanKey);
    if (keyIndex == -1) return nashvilleChord;

    return nashvilleChord.replaceAllMapped(RegExp(r'b7|[1-7]'), (match) {
      String number = match.group(0)!;
      int semitones = _intervals[number]!;
      int newIndex = (keyIndex + semitones) % 12;
      return _notes[newIndex];
    });
  }
}

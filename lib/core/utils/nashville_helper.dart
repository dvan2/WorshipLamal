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

  /// Main function: "6m" in Key of "C" -> "Am"
  static String translate(String nashvilleChord, String keyRoot) {
    if (nashvilleChord.isEmpty) return "";

    // Normalize Key (handle minor keys if needed, but usually we just take the root)
    // For simplicity, we assume keyRoot is like "C", "G", "F#"
    String cleanKey = keyRoot.replaceAll('m', '');

    // Find the starting index of the Key (e.g., C=0, G=7)
    int keyIndex = _notes.indexOf(cleanKey);
    if (keyIndex == -1) return nashvilleChord; // Fallback if key is invalid

    // Regex to find numbers 1-7 in the string
    // This handles complex chords like "1/3" or "6m7" automatically
    return nashvilleChord.replaceAllMapped(RegExp(r'b7|[1-7]'), (match) {
      String number = match.group(0)!;
      int semitones = _intervals[number]!;

      // Calculate new note index (wrapping around 12)
      int newIndex = (keyIndex + semitones) % 12;
      return _notes[newIndex];
    });
  }
}

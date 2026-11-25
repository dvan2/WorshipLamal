import 'music_theory.dart';

class NashvilleHelper {
  // Major Scale Intervals (semitones from root)
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

    // Normalize the key (handling enharmonics like Db -> C#)
    cleanKey = MusicTheory.normalizeNote(cleanKey);

    int keyIndex = MusicTheory.chromaticScale.indexOf(cleanKey);
    if (keyIndex == -1) return nashvilleChord;

    return nashvilleChord.replaceAllMapped(
      RegExp(r'(^|\s|/)(b7|[1-7])'),
      (match) {
        final prefix = match.group(1)!;
        final number = match.group(2)!;
        final semitones = _intervals[number]!;
        final newIndex = (keyIndex + semitones) % 12;
        final note = MusicTheory.chromaticScale[newIndex];
        return '$prefix$note';
      },
    );
  }
}

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

    return nashvilleChord.replaceAllMapped(RegExp(r'b7|[1-7]'), (match) {
      String number = match.group(0)!;
      int semitones = _intervals[number]!;
      int newIndex = (keyIndex + semitones) % 12;
      return MusicTheory.chromaticScale[newIndex];
    });
  }
}

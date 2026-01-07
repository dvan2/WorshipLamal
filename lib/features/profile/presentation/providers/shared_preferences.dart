import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Define keys here to avoid typos later
  static const _keyVocalMode = 'vocal_mode';
  static const _keyThemeMode = 'theme_mode';

  /// Save the vocal mode (0 = Original, 1 = Female)
  Future<void> saveVocalMode(int modeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyVocalMode, modeIndex);
  }

  /// Get the saved vocal mode (Default to 0/Original if nothing saved)
  Future<int> getVocalMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyVocalMode) ?? 0;
  }
}

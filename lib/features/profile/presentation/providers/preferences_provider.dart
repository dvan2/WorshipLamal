import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/profile/presentation/providers/shared_preferences.dart';

enum VocalMode { original, female }

enum ContentMode { lyrics, chords }

class PreferencesState {
  final VocalMode vocalMode;
  final bool isLoading;
  final ContentMode contentMode;

  const PreferencesState({
    // Defaults
    this.vocalMode = VocalMode.original,
    this.isLoading = true,
    this.contentMode = ContentMode.chords,
  });

  PreferencesState copyWith({
    VocalMode? vocalMode,
    bool? isLoading,
    ContentMode? contentMode,
  }) {
    return PreferencesState(
      vocalMode: vocalMode ?? this.vocalMode,
      isLoading: isLoading ?? this.isLoading,
      contentMode: contentMode ?? this.contentMode,
    );
  }
}

class PreferencesNotifier extends Notifier<PreferencesState> {
  final _service = PreferencesService();

  @override
  PreferencesState build() {
    _loadPreferences();
    return const PreferencesState(isLoading: true);
  }

  Future<void> _loadPreferences() async {
    // Load Vocal Mode
    final vocalIndex = await _service.getVocalMode();
    final vocalMode = VocalMode.values[vocalIndex];

    // 1. Load Content Mode
    final contentIndex = await _service.getContentMode();
    final contentMode = ContentMode.values[contentIndex];

    state = state.copyWith(
      vocalMode: vocalMode,
      contentMode: contentMode, // Update state
      isLoading: false,
    );
  }

  Future<void> setVocalMode(VocalMode mode) async {
    state = state.copyWith(vocalMode: mode);
    await _service.saveVocalMode(mode.index);
  }

  // 2. Add Setter for Content Mode
  Future<void> setContentMode(ContentMode mode) async {
    state = state.copyWith(contentMode: mode);
    await _service.saveContentMode(mode.index);
  }
}

// 3. The Provider
final preferencesProvider =
    NotifierProvider<PreferencesNotifier, PreferencesState>(() {
      return PreferencesNotifier();
    });

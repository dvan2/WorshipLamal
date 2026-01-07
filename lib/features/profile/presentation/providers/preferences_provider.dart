import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/profile/presentation/providers/shared_preferences.dart';

// Simple Enum for your modes
enum VocalMode { original, female }

// 1. The State Class
class PreferencesState {
  final VocalMode vocalMode;
  final bool isLoading;

  const PreferencesState({
    this.vocalMode = VocalMode.original,
    this.isLoading = true,
  });

  PreferencesState copyWith({VocalMode? vocalMode, bool? isLoading}) {
    return PreferencesState(
      vocalMode: vocalMode ?? this.vocalMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 2. The Notifier
class PreferencesNotifier extends Notifier<PreferencesState> {
  final _service = PreferencesService();

  @override
  PreferencesState build() {
    // Load the saved value immediately when the app starts
    _loadPreferences();
    return const PreferencesState(isLoading: true);
  }

  Future<void> _loadPreferences() async {
    final savedIndex = await _service.getVocalMode();
    // Convert integer back to Enum
    final mode = VocalMode.values[savedIndex];

    state = state.copyWith(vocalMode: mode, isLoading: false);
  }

  Future<void> setVocalMode(VocalMode mode) async {
    // 1. Update UI immediately (Optimistic update)
    state = state.copyWith(vocalMode: mode);

    // 2. Save to storage in background
    await _service.saveVocalMode(mode.index);
  }
}

// 3. The Provider
final preferencesProvider =
    NotifierProvider<PreferencesNotifier, PreferencesState>(() {
      return PreferencesNotifier();
    });

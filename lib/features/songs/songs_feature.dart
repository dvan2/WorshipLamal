// Models
export 'data/models/song_model.dart';
export 'data/models/lyric_line_model.dart';
export 'data/models/song_sort_option.dart';

// Repository (for testing, dependency injection)
export 'data/repositories/songs_repository.dart';
export 'data/repositories/history_repository.dart';

// Providers (for state consumption)
export 'presentation/providers/song_provider.dart';
export 'presentation/providers/song_filter_provider.dart';
export 'presentation/providers/display_key_provider.dart';
export 'presentation/providers/history_provider.dart';

// Main screens (navigation targets)
export 'presentation/screens/home_screen.dart';
export 'presentation/screens/song_detail_screen.dart';
export 'presentation/screens/song_results_screen.dart';

// Widgets used by other features
export 'presentation/widgets/song_search_field.dart';

// Utility for setlists feature
export 'presentation/utils/apply_song_filter.dart';

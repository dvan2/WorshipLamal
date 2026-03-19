import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/song_filter_bottom_sheet.dart';

class HomeDashboardTab extends ConsumerWidget {
  final VoidCallback onNavigateToSearch;

  const HomeDashboardTab({super.key, required this.onNavigateToSearch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Evening';
    if (hour < 12)
      greeting = 'Good Morning';
    else if (hour < 17)
      greeting = 'Good Afternoon';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          child: Text(
            greeting,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),

        // --- DUMMY SEARCH BAR ---
        GestureDetector(
          onTap: () {
            ref.read(songFilterProvider.notifier).resetAll();
            ref.read(searchQueryProvider.notifier).clear();
            onNavigateToSearch();
          },
          child: AbsorbPointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search songs, artists, or keys...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // --- Quick Toggles ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickPill(
                label: "Favorites",
                icon: Icons.favorite,
                onTap: () {
                  ref
                      .read(songFilterProvider.notifier)
                      .applyExclusiveFilter(favoritesOnly: true);
                  onNavigateToSearch();
                },
              ),
              const SizedBox(width: 8),
              _QuickPill(
                label: "Hymns",
                icon: Icons.auto_stories,
                onTap: () {
                  ref.read(songFilterProvider.notifier).resetAll();
                  ref
                      .read(songFilterProvider.notifier)
                      .toggleType(SongType.hymn);
                  onNavigateToSearch();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Hero Cards ---
        Row(
          children: [
            Expanded(
              child: _HeroCard(
                title: "Deep Worship",
                subtitle: "Slow & Intimate",
                icon: Icons.waves,
                colorStart: Colors.indigo.shade400,
                colorEnd: Colors.purple.shade700,
                onTap: () {
                  ref.read(songFilterProvider.notifier).resetAll();
                  ref
                      .read(songFilterProvider.notifier)
                      .toggleType(SongType.worship);
                  onNavigateToSearch();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _HeroCard(
                title: "High Praise",
                subtitle: "Fast & Energetic",
                icon: Icons.local_fire_department,
                colorStart: Colors.orange.shade400,
                colorEnd: Colors.red.shade700,
                onTap: () {
                  ref.read(songFilterProvider.notifier).resetAll();
                  ref
                      .read(songFilterProvider.notifier)
                      .toggleType(SongType.praise);
                  onNavigateToSearch();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // --- Browse by Key Shelf ---
        const Text(
          "Browse by Key",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _KeyCard(
                keyName: "C",
                color: Colors.red.shade400,
                ref: ref,
                onNav: onNavigateToSearch,
              ),
              _KeyCard(
                keyName: "D",
                color: Colors.blue.shade400,
                ref: ref,
                onNav: onNavigateToSearch,
              ),
              _KeyCard(
                keyName: "E",
                color: Colors.green.shade400,
                ref: ref,
                onNav: onNavigateToSearch,
              ),
              _KeyCard(
                keyName: "G",
                color: Colors.orange.shade400,
                ref: ref,
                onNav: onNavigateToSearch,
              ),
              _KeyCard(
                keyName: "A",
                color: Colors.purple.shade400,
                ref: ref,
                onNav: onNavigateToSearch,
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ====================================================================
// SUB-WIDGETS FOR DASHBOARD
// ====================================================================

class _QuickPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.textPrimary),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.surfaceVariant,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color colorStart;
  final Color colorEnd;
  final VoidCallback onTap;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorStart,
    required this.colorEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [colorStart, colorEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorStart.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  final String keyName;
  final Color color;
  final WidgetRef ref;
  final VoidCallback onNav;

  const _KeyCard({
    required this.keyName,
    required this.color,
    required this.ref,
    required this.onNav,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ref
                .read(songFilterProvider.notifier)
                .applyExclusiveFilter(keyName: keyName);
            onNav();
          },
          child: Container(
            width: 90,
            alignment: Alignment.center,
            child: Text(
              keyName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// NOTE: Your existing SongSearchField code remains identical,
// so paste your `SongSearchField` and `_SongSearchFieldState` classes right below this!

class SongSearchField extends ConsumerStatefulWidget {
  final NotifierProvider<SearchQueryNotifier, String> searchProvider;
  final NotifierProvider<SongFilterNotifier, SongFilterState> filterProvider;

  const SongSearchField({
    super.key,
    required this.searchProvider,
    required this.filterProvider,
  });

  @override
  ConsumerState<SongSearchField> createState() => _SongSearchFieldState();
}

class _SongSearchFieldState extends ConsumerState<SongSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(widget.searchProvider);
    final filterState = ref.watch(widget.filterProvider);
    final hasFilters = filterState.isFiltering;

    // Sync Controller with Provider
    ref.listen(widget.searchProvider, (previous, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
      }
    });

    return Row(
      children: [
        // 1. EXPANDED SEARCH BAR
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: (value) {
              ref.read(widget.searchProvider.notifier).setQuery(value);
            },
            decoration: InputDecoration(
              hintText: 'Search songs...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              // Only the Clear Button lives here now
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          ref.read(widget.searchProvider.notifier).clear(),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ), // Matching rounded corners
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              isDense: true, // Makes it look slightly more compact/modern
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. DETACHED FILTER BUTTON
        // Provides a consistent, large touch target that never moves
        Material(
          color: AppColors.surfaceVariant, // Match search bar color
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => SongFilterBottomSheet(
                  targetProvider: widget.filterProvider,
                ),
              );
            },
            child: Container(
              height: 48, // Standard touch target height
              width: 48,
              alignment: Alignment.center,
              child: Badge(
                isLabelVisible: hasFilters,
                backgroundColor: AppColors.primary,
                smallSize: 8,
                child: Icon(
                  Icons.tune_rounded, // Rounded variant looks softer
                  color: hasFilters
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

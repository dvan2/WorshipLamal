import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';

class HomeDashboardTab extends ConsumerWidget {
  final VoidCallback onNavigateToSearch;

  const HomeDashboardTab({super.key, required this.onNavigateToSearch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Evening';
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
      children: [
        // --- Elevated Greeting ---
        Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Ready to lead today?",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // --- Floating DUMMY SEARCH BAR ---
        GestureDetector(
          onTap: () {
            ref.read(songFilterProvider.notifier).resetAll();
            ref.read(searchQueryProvider.notifier).clear();
            onNavigateToSearch();
          },
          child: AbsorbPointer(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, or keys...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white, // Pop against a slightly off-white scaffold
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), // Softer corners
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // --- Quick Toggles ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none, // Allows focus shadows to show
          child: Row(
            children: [
              _QuickPill(
                label: "Favorites",
                icon: Icons.favorite,
                iconColor: const Color(0xFFF04B43), // Red from icon
                onTap: () {
                  ref
                      .read(songFilterProvider.notifier)
                      .applyExclusiveFilter(favoritesOnly: true);
                  onNavigateToSearch();
                },
              ),
              const SizedBox(width: 12),
              _QuickPill(
                label: "Hymns",
                icon: Icons.auto_stories,
                iconColor: const Color(0xFF1354A1), // Blue from icon
                onTap: () {
                  ref
                      .read(songFilterProvider.notifier)
                      .applyExclusiveFilter(type: SongType.hymn);
                  onNavigateToSearch();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // --- Hero Cards (Icon Color Palette) ---
        Row(
          children: [
            Expanded(
              child: _HeroCard(
                title: "Deep\nWorship",
                subtitle: "Slow & Intimate",
                icon: Icons.waves,
                // Colors extracted from the bottom/left of your icon
                colorStart: const Color(0xFF1354A1), // Deep Blue
                colorEnd: const Color(0xFF23C4F4), // Bright Cyan
                onTap: () {
                  ref
                      .read(songFilterProvider.notifier)
                      .applyExclusiveFilter(type: SongType.worship);
                  onNavigateToSearch();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _HeroCard(
                title: "High\nPraise",
                subtitle: "Fast & Energetic",
                icon: Icons.local_fire_department,
                // Colors extracted from the top/right of your icon
                colorStart: const Color(0xFFF04B43), // Vivid Red
                colorEnd: const Color(0xFFF89921), // Bright Orange/Yellow
                onTap: () {
                  ref
                      .read(songFilterProvider.notifier)
                      .applyExclusiveFilter(type: SongType.praise);
                  onNavigateToSearch();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),

        // --- Browse by Key Shelf ---
        const Text(
          "Browse by Key",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100, // Slightly taller for better touch targets
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _KeyCard(
                keyName: "C",
                color: const Color(0xFF1354A1),
                ref: ref,
                onNav: onNavigateToSearch,
              ), // Deep Blue
              _KeyCard(
                keyName: "D",
                color: const Color(0xFF23C4F4),
                ref: ref,
                onNav: onNavigateToSearch,
              ), // Cyan
              _KeyCard(
                keyName: "E",
                color: const Color(0xFFF04B43),
                ref: ref,
                onNav: onNavigateToSearch,
              ), // Red
              _KeyCard(
                keyName: "G",
                color: const Color(0xFFF89921),
                ref: ref,
                onNav: onNavigateToSearch,
              ), // Orange
              _KeyCard(
                keyName: "A",
                color: const Color(0xFF7E57C2),
                ref: ref,
                onNav: onNavigateToSearch,
              ), // Purple complement
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
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickPill({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: iconColor),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      side: BorderSide(color: Colors.grey.shade200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      pressElevation: 2,
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
        borderRadius: BorderRadius.circular(24), // Match icon squircle
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [colorStart, colorEnd],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorStart.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6), // Creates a "floating" paper effect
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.only(right: 14),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20), // Softer corners
        elevation: 4, // Add subtle shadow
        shadowColor: color.withOpacity(0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref
                .read(songFilterProvider.notifier)
                .applyExclusiveFilter(keyName: keyName);
            onNav();
          },
          child: Container(
            width: 85,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Add a very subtle gradient to the key cards to match the app theme
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              keyName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

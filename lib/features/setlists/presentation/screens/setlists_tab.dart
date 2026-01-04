import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/widgets/create_setlist_dialog.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/widgets/setlist_card.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/widgets/setlist_section_header.dart';

class SetlistsTab extends ConsumerWidget {
  const SetlistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mySetlistsAsync = ref.watch(setlistsListProvider);
    final followedSetlistsAsync = ref.watch(followedSetlistsProvider);

    return Stack(
      children: [
        // FAB (Positioned First or Last depending on if you want it over content)
        // Usually put LAST in a Stack to be on top, but here works too.
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const CreateSetlistDialog(),
            ),
          ),
        ),

        Expanded(
          child: mySetlistsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (mySetlists) {
              return followedSetlistsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (followedSetlists) {
                  if (mySetlists.isEmpty && followedSetlists.isEmpty) {
                    return _EmptySetlistState();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomScrollView(
                      slivers: [
                        // --- SECTION A: MY SETLISTS ---
                        if (mySetlists.isNotEmpty) ...[
                          const SetlistSectionHeader(title: "My Setlists"),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => SetlistCard(
                                setlist: mySetlists[index],
                                isOwner: true,
                              ),
                              childCount: mySetlists.length,
                            ),
                          ),
                        ],

                        // --- SPACING ---
                        if (mySetlists.isNotEmpty &&
                            followedSetlists.isNotEmpty)
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),

                        // --- SECTION B: FOLLOWED ---
                        if (followedSetlists.isNotEmpty) ...[
                          const SetlistSectionHeader(title: "Following"),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => SetlistCard(
                                setlist: followedSetlists[index],
                                isOwner: false,
                              ),
                              childCount: followedSetlists.length,
                            ),
                          ),
                        ],

                        // Bottom Spacer for FAB
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptySetlistState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            "No setlists yet",
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text("Tap the + button to create one"),
        ],
      ),
    );
  }
}

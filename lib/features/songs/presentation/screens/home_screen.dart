import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/profile/presentation/profile_tab.dart';
import 'package:worship_lamal/features/songs/presentation/screens/setlists_tab.dart';
import 'songs_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // The list of pages to switch between
  final List<Widget> _tabs = const [SongsTab(), SetlistsTab(), ProfileTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(),
        centerTitle: false,
        actions: [
          ..._buildActions(),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 20,
                color: AppColors.primary,
              ),
              // On tap: navigate to Profile tab?
            ),
          ),
        ],
      ),
      // Switch the body based on the index
      body: _tabs[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note),
            label: 'Songs',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music),
            label: 'Setlists',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    switch (_currentIndex) {
      case 0:
        return Row(
          children: [
            // Optional: Small Logo Icon
            const Icon(Icons.menu_book, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Worship Lamal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 22,
              ),
            ),
          ],
        );
      case 1:
        return const Text(
          'My Setlists',
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      case 2:
        return const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      default:
        return const SizedBox();
    }
  }

  List<Widget> _buildActions() {
    switch (_currentIndex) {
      case 0: // Songs Tab
        return [
          // IconButton(
          //   icon: const Icon(Icons.filter_list),
          //   tooltip: "Filter Songs",
          //   onPressed: () {
          //     // TODO: Show filter bottom sheet
          //   },
          // ),
        ];
      case 1: // Setlists Tab
        return [
          IconButton(
            icon: const Icon(Icons.input),
            tooltip: "Join Setlist via ID",
            onPressed: () {
              _showJoinByIdDialog(context);
            },
          ),
        ];
      default:
        return [];
    }
  }
}

Future<void> _showJoinByIdDialog(BuildContext context) async {
  final controller = TextEditingController();

  // Show Dialog and wait for result
  final setlistId = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Join Setlist by ID'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Paste UUID here...',
          border: OutlineInputBorder(),
          helperText: "Get this ID from the setlist owner",
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, controller.text.trim());
          },
          child: const Text('Go'),
        ),
      ],
    ),
  );

  if (setlistId != null && setlistId.isNotEmpty && context.mounted) {
    context.pushNamed('setlistDetail', pathParameters: {'id': setlistId});
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/profile/presentation/profile_tab.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlists_tab.dart';
// Note: You will create these two files in Step 2 & 3
import 'home_dashboard_tab.dart';
import 'song_list_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  void _navigateToSongsTab() {
    setState(() {
      _currentIndex = 1; // 1 is the index of the SongListTab
    });
  }

  @override
  Widget build(BuildContext context) {
    // We generate the tabs here so we can pass the navigation callback to the Dashboard
    final List<Widget> tabs = [
      HomeDashboardTab(onNavigateToSearch: _navigateToSongsTab), // Index 0
      const SongListTab(), // Index 1
      const SetlistsTab(), // Index 2
      const ProfileTab(), // Index 3
    ];

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
            ),
          ),
        ],
      ),
      body: tabs[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
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
      case 0: // Home
        return Row(
          children: [
            Container(
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Worship Lamal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
            ),
          ],
        );
      case 1: // Songs/Search
        return const Text(
          'All Songs',
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      case 2: // Setlists
        return const Text(
          'Setlists',
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      case 3: // Profile
        return const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      default:
        return const SizedBox();
    }
  }

  List<Widget> _buildActions() {
    if (_currentIndex == 2) {
      // Setlists Tab
      return [
        IconButton(
          icon: const Icon(Icons.input),
          tooltip: "Join Setlist via ID",
          onPressed: () {
            _showJoinByIdDialog(context);
          },
        ),
      ];
    }
    return [];
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

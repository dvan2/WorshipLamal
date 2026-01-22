import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/profile/presentation/login_screen.dart';
import 'package:worship_lamal/features/profile/presentation/signup_screen.dart';
import 'package:worship_lamal/features/songs/data/repositories/auth_repository.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  final _repo = AuthRepository();

  @override
  Widget build(BuildContext context) {
    final user = _repo.currentUser;
    // 1. Watch the Preferences State
    final prefsState = ref.watch(preferencesProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isGuest = user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile & Settings"),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // 2. HEADER SECTION (Dynamic based on user type)
          _buildHeader(user, isGuest),

          const Divider(height: 32),

          // 3. AUDIO PREFERENCES (The New Feature)
          _buildSectionTitle("Preferences"),

          ListTile(
            title: const Text("Vocal Mode"),
            subtitle: Text(
              prefsState.vocalMode == VocalMode.original
                  ? "Male Keys (Original)"
                  : "Female Keys (Auto-Lowered)",
            ),
            trailing: SegmentedButton<VocalMode>(
              segments: const [
                ButtonSegment(
                  value: VocalMode.original,
                  label: Text("Male"),
                  icon: Icon(Icons.music_note),
                ),
                ButtonSegment(
                  value: VocalMode.female,
                  label: Text("Fem"),
                  icon: Icon(Icons.person_3), // Female icon
                ),
              ],
              selected: {prefsState.vocalMode},
              onSelectionChanged: (Set<VocalMode> newSelection) {
                // Update the provider
                ref
                    .read(preferencesProvider.notifier)
                    .setVocalMode(newSelection.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

          ListTile(
            title: const Text("Display Mode"),
            subtitle: Text(
              prefsState.contentMode == ContentMode.lyrics
                  ? "Show Lyrics Only"
                  : "Show Chords & Lyrics",
            ),
            trailing: SegmentedButton<ContentMode>(
              segments: const [
                ButtonSegment(
                  value: ContentMode.lyrics,
                  label: Text("Lyrics"),
                  icon: Icon(Icons.text_fields),
                ),
                ButtonSegment(
                  value: ContentMode.chords,
                  label: Text("Chords"),
                  icon: Icon(Icons.music_note),
                ),
              ],
              selected: {prefsState.contentMode},
              onSelectionChanged: (Set<ContentMode> newSelection) {
                ref
                    .read(preferencesProvider.notifier)
                    .setContentMode(newSelection.first);
              },
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

          const Divider(height: 32),

          // 4. ACCOUNT ACTIONS
          _buildSectionTitle("Account"),

          if (isGuest) ...[
            // Guest Specific Actions
            ListTile(
              leading: const Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.primary,
              ),
              title: const Text("Sync Data"),
              subtitle: const Text("Create an account to save setlists"),
              onTap: () => _navigateTo(const SignUpScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text("Log In"),
              onTap: () => _navigateTo(const LoginScreen()),
            ),
          ] else ...[
            // Logged In Actions
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Sign Out",
                style: TextStyle(color: Colors.red),
              ),
              onTap: _handleSignOut,
            ),
          ],

          // Version Number (Good practice)
          const SizedBox(height: 40),
          const Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User user, bool isGuest) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: isGuest
                ? Colors.grey.shade200
                : AppColors.primary.withOpacity(0.1),
            child: Icon(
              isGuest ? Icons.person_outline : Icons.person,
              size: 40,
              color: isGuest ? Colors.grey : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest ? "Guest Account" : (user.email ?? "User"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isGuest)
                  const Text(
                    "Settings are saved to this device.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  )
                else
                  const Text(
                    "Account Synced ✅",
                    style: TextStyle(color: Colors.green, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    if (mounted) setState(() {});
  }

  Future<void> _handleSignOut() async {
    await _repo.signOut();
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (e) {
      debugPrint("Error signing in anonymously: $e");
    }
    if (mounted) setState(() {});
  }
}

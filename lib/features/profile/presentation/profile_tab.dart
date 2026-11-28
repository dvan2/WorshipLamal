import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/core/routing/app_router.dart';
import 'package:worship_lamal/core/services/push_notification_provider.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/utils/web_url_cleaner.dart';
import 'package:worship_lamal/features/profile/presentation/changelog_screen.dart';
import 'package:worship_lamal/features/profile/presentation/login_screen.dart';
import 'package:worship_lamal/features/profile/presentation/signup_screen.dart';
import 'package:worship_lamal/features/profile/presentation/providers/auth_provider.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/profile/presentation/widgets/google_sign_in_button.dart';
import 'package:worship_lamal/features/profile/presentation/widgets/push_notification_tile.dart';

const kFallbackVersion = "1.3.0";
const kFallbackBuild = "10";

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();

    // On Web, sometimes these come back empty if version.json fails
    if (info.version.isEmpty || info.version == 'unknown') {
      // Return a fake PackageInfo with your fallback values
      return PackageInfo(
        appName: 'Worship Lamal',
        packageName: 'com.example.worship_lamal',
        version: kFallbackVersion,
        buildNumber: kFallbackBuild,
        buildSignature: '',
      );
    }

    return info;
  } catch (e) {
    // If it crashes completely, return fallback
    return PackageInfo(
      appName: 'Worship Lamal',
      packageName: 'com.example.worship_lamal',
      version: kFallbackVersion,
      buildNumber: kFallbackBuild,
      buildSignature: '',
    );
  }
});

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  bool _isSigningOut = false;
  bool _isRetryingGuest = false;

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateProvider);
    final user =
        authStateAsync.asData?.value.session?.user ??
        ref.watch(authRepositoryProvider).currentUser;
    // 1. Watch the Preferences State
    final prefsState = ref.watch(preferencesProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    if (user == null) {
      return _buildSignedOutFallback(context);
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

          if (kIsWeb)
            PushNotificationTile(
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32),
                  _buildSectionTitle("Notifications"),
                ],
              ),
            ),

          const Divider(height: 32),

          // 4. ACCOUNT ACTIONS
          _buildSectionTitle("Account"),

          if (isGuest) ...[
            // Guest Specific Actions
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GoogleSignInButton(),
            ),
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
          Center(
            child: packageInfoAsync.when(
              data: (info) => Text(
                "Version ${info.version} (Build ${info.buildNumber})",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const Text("Version Unknown"),
            ),
          ),

          _buildSectionTitle("App Info"),

          ListTile(
            leading: const Icon(
              Icons.new_releases_outlined,
              color: Colors.orange,
            ),
            title: const Text("What's New"),
            subtitle: const Text("See recent updates and changes"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangelogScreen(),
                ),
              );
            },
          ),

          const Divider(height: 32),
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
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    try {
      // Delete the outgoing user's push subscription while auth.uid() is still
      // valid under RLS before signing out.
      try {
        final sub = await ref
            .read(pushNotificationServiceProvider)
            .getCurrentSubscription();
        if (sub != null) {
          await ref
              .read(pushSubscriptionRepositoryProvider)
              .deleteSubscription(sub.endpoint);
        }
      } catch (e) {
        debugPrint("Error deleting push subscription on sign-out: $e");
      }

      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();

      try {
        await repo.signInAnonymously();
      } catch (e) {
        debugPrint("Error signing in anonymously: $e");
      }

      if (kIsWeb) {
        try {
          scrubOAuthParamsFromBrowserUrl();
          final cleaned = cleanedOAuthRelativeLocation(Uri.base);
          if (cleaned != null) {
            appRouter.go(cleaned);
          }
        } catch (_) {
          // Best-effort URL cleanup after sign-out.
        }
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  Widget _buildSignedOutFallback(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile & Settings"),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Not Signed In',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You appear to be offline or signed out. Retry creating a guest session or sign in with your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isRetryingGuest ? null : _retryGuestSession,
                      icon: _isRetryingGuest
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Retry Guest Session'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateTo(const LoginScreen()),
                      icon: const Icon(Icons.login),
                      label: const Text('Log In'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _retryGuestSession() async {
    if (_isRetryingGuest) return;
    setState(() => _isRetryingGuest = true);
    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start guest session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRetryingGuest = false);
    }
  }
}

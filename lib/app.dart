import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/core/services/push_notification_provider.dart';
import 'package:worship_lamal/core/theme/app_theme.dart';
import 'package:worship_lamal/features/favorites/favorites_feature.dart';
import 'package:worship_lamal/features/profile/profile_feature.dart';
import 'package:worship_lamal/features/songs/songs_feature.dart';
import 'core/routing/app_router.dart';

/// Returns true when [uri] carries an `identity_already_exists` OAuth error
/// in either its query parameters or fragment.
bool hasIdentityAlreadyExistsError(Uri uri) {
  if (uri.queryParameters['error_code'] ==
          AuthRepository.identityAlreadyExistsCode ||
      uri.queryParameters['error'] ==
          AuthRepository.identityAlreadyExistsCode) {
    return true;
  }

  if (uri.fragment.isNotEmpty) {
    try {
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      if (fragmentParams['error_code'] ==
              AuthRepository.identityAlreadyExistsCode ||
          fragmentParams['error'] == AuthRepository.identityAlreadyExistsCode) {
        return true;
      }
    } catch (_) {
      if (uri.fragment.contains(AuthRepository.identityAlreadyExistsCode)) {
        return true;
      }
    }
  }

  return false;
}

class WorshipLamal extends StatelessWidget {
  const WorshipLamal({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        favoriteSongIdsProvider.overrideWith((ref) {
          final favAsync = ref.watch(favoritesListProvider);
          return favAsync.whenData(
            (favs) => favs.map((f) => f.songId).toSet(),
          );
        }),
      ],
      child: const _AuthCallbackHost(),
    );
  }
}

class _AuthCallbackHost extends ConsumerStatefulWidget {
  const _AuthCallbackHost();

  @override
  ConsumerState<_AuthCallbackHost> createState() => _AuthCallbackHostState();
}

class _AuthCallbackHostState extends ConsumerState<_AuthCallbackHost> {
  bool _handledInitialUriError = false;
  bool _isPromptingSwitch = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !_handledInitialUriError) {
      _handledInitialUriError = true;
      if (hasIdentityAlreadyExistsError(Uri.base)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _promptSwitchAccount();
        });
      }
    }
  }

  Future<void> _promptSwitchAccount() async {
    if (_isPromptingSwitch || !mounted) return;
    final navigatorContext = appRouter.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;

    _isPromptingSwitch = true;
    try {
      final shouldSwitch = await showDialog<bool>(
        context: navigatorContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Account Already Linked'),
          content: const Text(
            'This Google account is already linked to an existing account. '
            'Switch to that account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Switch Account'),
            ),
          ],
        ),
      );

      if (shouldSwitch != true || !mounted) return;

      if (kIsWeb) {
        try {
          final sub = await ref
              .read(pushNotificationServiceProvider)
              .getCurrentSubscription();
          if (sub != null) {
            await ref
                .read(pushSubscriptionRepositoryProvider)
                .deleteSubscription(sub.endpoint);
          }
        } catch (_) {
          // Do not block account switch on push cleanup failure.
        }
      }

      await ref.read(authRepositoryProvider).signInWithGoogle(forceSignIn: true);
    } finally {
      _isPromptingSwitch = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      if (next is AsyncError && next.error is AuthException) {
        final err = next.error as AuthException;
        final isAlreadyLinked =
            err.code == AuthRepository.identityAlreadyExistsCode ||
            err.message.toLowerCase().contains('already');
        if (isAlreadyLinked) {
          _promptSwitchAccount();
        }
      }
    });

    return MaterialApp.router(
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
    );
  }
}

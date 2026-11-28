import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/core/services/push_notification_provider.dart';
import 'package:worship_lamal/core/theme/app_theme.dart';
import 'package:worship_lamal/core/utils/web_url_cleaner.dart';
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
      child: const AuthCallbackHost(),
    );
  }
}

/// Hosts the root router and handles OAuth `identity_already_exists` callbacks.
class AuthCallbackHost extends ConsumerStatefulWidget {
  final Widget? child;
  final Uri? initialUri;
  final VoidCallback? onScrubUrl;
  final bool? isWebOverride;
  final GlobalKey<NavigatorState>? navigatorKey;

  const AuthCallbackHost({
    super.key,
    this.child,
    this.initialUri,
    this.onScrubUrl,
    this.isWebOverride,
    this.navigatorKey,
  });

  @override
  ConsumerState<AuthCallbackHost> createState() => _AuthCallbackHostState();
}

class _AuthCallbackHostState extends ConsumerState<AuthCallbackHost> {
  bool _handledInitialUriError = false;
  bool _isPromptingSwitch = false;
  bool _dismissedOAuthError = false;

  bool get _isWeb => widget.isWebOverride ?? kIsWeb;

  @override
  void initState() {
    super.initState();
    if (_isWeb && !_handledInitialUriError) {
      _handledInitialUriError = true;
      final uri = widget.initialUri ?? Uri.base;
      if (hasIdentityAlreadyExistsError(uri)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _promptSwitchAccount();
        });
      }
    }
  }

  Future<void> _cleanupPushSubscriptionBestEffort() async {
    try {
      final sub = await ref
          .read(pushNotificationServiceProvider)
          .getCurrentSubscription()
          .timeout(const Duration(milliseconds: 300));
      if (sub != null) {
        await ref
            .read(pushSubscriptionRepositoryProvider)
            .deleteSubscription(sub.endpoint)
            .timeout(const Duration(milliseconds: 300));
      }
    } catch (_) {
      // Best-effort cleanup; never block or fail account switch.
    }
  }

  Future<void> _promptSwitchAccount() async {
    if (_isPromptingSwitch || _dismissedOAuthError || !mounted) return;
    final navigatorContext =
        (widget.navigatorKey ?? appRouter.routerDelegate.navigatorKey)
            .currentContext;
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

      if (_isWeb) {
        (widget.onScrubUrl ?? scrubOAuthErrorFromBrowserUrl)();
      }

      if (shouldSwitch != true) {
        _dismissedOAuthError = true;
        return;
      }

      if (!mounted) return;

      if (_isWeb) {
        unawaited(_cleanupPushSubscriptionBestEffort());
      }

      try {
        await ref
            .read(authRepositoryProvider)
            .signInWithGoogle(forceSignIn: true);
      } catch (e) {
        if (navigatorContext.mounted) {
          ScaffoldMessenger.maybeOf(navigatorContext)?.showSnackBar(
            SnackBar(
              content: Text(
                'Google Sign-In failed: ${e.toString().replaceAll('AuthException:', '').trim()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      _isPromptingSwitch = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      if (next is AsyncData<AuthState> &&
          next.value.event == AuthChangeEvent.signedIn) {
        _dismissedOAuthError = false;
        return;
      }
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

    if (widget.child != null) {
      return widget.child!;
    }

    return MaterialApp.router(
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuestDataSummary {
  final bool hasSetlists;
  final bool hasUserKeys;
  final bool hasFavorites;

  const GuestDataSummary({
    this.hasSetlists = false,
    this.hasUserKeys = false,
    this.hasFavorites = false,
  });

  bool get hasAny => hasSetlists || hasUserKeys || hasFavorites;
}

typedef GuestDataCheckerFn = Future<GuestDataSummary> Function(String userId);
typedef LinkOAuthFn = Future<bool> Function(
  OAuthProvider provider, {
  String? redirectTo,
});
typedef SignInOAuthFn = Future<bool> Function(
  OAuthProvider provider, {
  String? redirectTo,
});
typedef OAuthRedirectUriFn = String? Function();

class AuthRepository {
  static const String identityAlreadyExistsCode = 'identity_already_exists';

  final SupabaseClient _client;
  final GuestDataCheckerFn? _guestDataChecker;
  final LinkOAuthFn? _linkOAuthFn;
  final SignInOAuthFn? _signInOAuthFn;
  final OAuthRedirectUriFn _redirectUriFn;

  AuthRepository(
    this._client, {
    GuestDataCheckerFn? guestDataChecker,
    LinkOAuthFn? linkOAuthFn,
    SignInOAuthFn? signInOAuthFn,
    OAuthRedirectUriFn? redirectUriFn,
  })  : _guestDataChecker = guestDataChecker,
        _linkOAuthFn = linkOAuthFn,
        _signInOAuthFn = signInOAuthFn,
        _redirectUriFn =
            redirectUriFn ?? (() => kIsWeb ? Uri.base.origin : null);

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<GuestDataSummary> getGuestDataSummary() async {
    final user = currentUser;
    if (user == null || !user.isAnonymous) {
      return const GuestDataSummary();
    }

    if (_guestDataChecker != null) {
      return _guestDataChecker(user.id);
    }

    final results = await Future.wait([
      _hasRows('setlists', 'id', user.id),
      _hasRows('user_keys', 'song_id', user.id),
      _hasRows('favorites', 'song_id', user.id),
    ]);

    return GuestDataSummary(
      hasSetlists: results[0],
      hasUserKeys: results[1],
      hasFavorites: results[2],
    );
  }

  Future<bool> _hasRows(String table, String column, String userId) async {
    final rows = await _client
        .from(table)
        .select(column)
        .eq('user_id', userId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> signInAnonymously() async {
    await _client.auth.signInAnonymously();
  }

  Future<void> upgradeGuestAccount(String email, String password) async {
    // This converts the anonymous user to a permanent one
    await _client.auth.updateUser(
      UserAttributes(email: email, password: password),
    );
  }

  /// Signs in with Google OAuth.
  ///
  /// For anonymous guests (unless [forceSignIn] is true), attempts
  /// `linkIdentity` first to preserve the guest's `user_id`, falling back to
  /// `signInWithOAuth` if the Google identity is already linked to another user.
  Future<void> signInWithGoogle({
    String? redirectTo,
    bool forceSignIn = false,
  }) async {
    final resolvedRedirect = redirectTo ?? _redirectUriFn();
    final isGuest = currentUser?.isAnonymous ?? false;

    final launchMode =
        kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;

    if (isGuest && !forceSignIn) {
      try {
        final linkFn = _linkOAuthFn ??
            (provider, {redirectTo}) => _client.auth.linkIdentity(
                  provider,
                  redirectTo: redirectTo,
                  authScreenLaunchMode: launchMode,
                );
        final linked =
            await linkFn(OAuthProvider.google, redirectTo: resolvedRedirect);
        if (!linked) {
          throw const AuthException(
            'Could not open Google sign-in. Please try again.',
          );
        }
        return;
      } on AuthException catch (e) {
        final isAlreadyLinked =
            e.code == identityAlreadyExistsCode ||
            e.message.toLowerCase().contains('already');
        if (!isAlreadyLinked) rethrow;
      }
    }

    final signInFn = _signInOAuthFn ??
        (provider, {redirectTo}) => _client.auth.signInWithOAuth(
              provider,
              redirectTo: redirectTo,
              authScreenLaunchMode: launchMode,
            );
    final launched =
        await signInFn(OAuthProvider.google, redirectTo: resolvedRedirect);
    if (!launched) {
      throw const AuthException(
        'Could not open Google sign-in. Please try again.',
      );
    }
  }
}

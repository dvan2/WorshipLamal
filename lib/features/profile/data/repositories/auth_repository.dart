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

class AuthRepository {
  final SupabaseClient _client;
  final GuestDataCheckerFn? _guestDataChecker;

  AuthRepository(this._client, {GuestDataCheckerFn? guestDataChecker})
    : _guestDataChecker = guestDataChecker;

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
}

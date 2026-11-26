import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_notification_service.dart';

typedef UpsertPushRowFn = Future<void> Function(Map<String, dynamic> row);
typedef DeletePushRowFn = Future<void> Function(
  String userId,
  String endpoint,
);

/// Repository for persisting browser Web Push subscriptions in Supabase.
class PushSubscriptionRepository {
  final SupabaseClient _client;
  final UpsertPushRowFn? _upsertFn;
  final DeletePushRowFn? _deleteFn;

  const PushSubscriptionRepository(
    this._client, {
    UpsertPushRowFn? upsertFn,
    DeletePushRowFn? deleteFn,
  })  : _upsertFn = upsertFn,
        _deleteFn = deleteFn;

  /// Upserts [data] for the currently authenticated user.
  Future<void> saveSubscription(PushSubscriptionData data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final row = {
      'user_id': userId,
      'endpoint': data.endpoint,
      'p256dh': data.p256dh,
      'auth': data.auth,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (_upsertFn != null) {
      await _upsertFn(row);
      return;
    }

    await _client
        .from('push_subscriptions')
        .upsert(row, onConflict: 'user_id,endpoint');
  }

  /// Deletes the subscription matching [endpoint] for the current user.
  Future<void> deleteSubscription(String endpoint) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (_deleteFn != null) {
      await _deleteFn(userId, endpoint);
      return;
    }

    await _client
        .from('push_subscriptions')
        .delete()
        .eq('user_id', userId)
        .eq('endpoint', endpoint);
  }
}

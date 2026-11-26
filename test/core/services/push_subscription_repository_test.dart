import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worship_lamal/core/services/push_notification_service.dart';
import 'package:worship_lamal/core/services/push_subscription_repository.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late List<Map<String, dynamic>> upsertedRows;
  late List<(String, String)> deletedCalls;
  late PushSubscriptionRepository repository;

  const testSub = PushSubscriptionData(
    endpoint: 'https://push.example.com/sub/abc',
    p256dh: 'p256dh-test',
    auth: 'auth-test',
  );

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    upsertedRows = [];
    deletedCalls = [];

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockUser.id).thenReturn('user-123');

    repository = PushSubscriptionRepository(
      mockClient,
      upsertFn: (row) async => upsertedRows.add(row),
      deleteFn: (userId, endpoint) async =>
          deletedCalls.add((userId, endpoint)),
    );
  });

  group('PushSubscriptionRepository', () {
    test('saveSubscription no-ops when currentUser is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      await repository.saveSubscription(testSub);

      expect(upsertedRows, isEmpty);
    });

    test('saveSubscription upserts row with current user id and keys',
        () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await repository.saveSubscription(testSub);

      expect(upsertedRows, hasLength(1));
      final row = upsertedRows.first;
      expect(row['user_id'], 'user-123');
      expect(row['endpoint'], testSub.endpoint);
      expect(row['p256dh'], testSub.p256dh);
      expect(row['auth'], testSub.auth);
      expect(row['updated_at'], isA<String>());
    });

    test('deleteSubscription no-ops when currentUser is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      await repository.deleteSubscription(testSub.endpoint);

      expect(deletedCalls, isEmpty);
    });

    test('deleteSubscription deletes matching userId and endpoint', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await repository.deleteSubscription(testSub.endpoint);

      expect(deletedCalls, [('user-123', testSub.endpoint)]);
    });
  });
}

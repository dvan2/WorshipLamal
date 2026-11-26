import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/core/config/supabase_config.dart';
import 'package:worship_lamal/features/profile/presentation/providers/auth_provider.dart';
import 'package:worship_lamal/features/songs/data/repositories/history_repository.dart';
import 'package:worship_lamal/features/songs/presentation/providers/history_provider.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _FakeSession extends Fake implements Session {
  @override
  final User user;

  _FakeSession(this.user);
}

void main() {
  late _MockHistoryRepository mockHistoryRepo;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late StreamController<AuthState> authController;

  setUp(() {
    mockHistoryRepo = _MockHistoryRepository();
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    authController = StreamController<AuthState>.broadcast();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
  });

  tearDown(() async {
    await authController.close();
  });

  test('recentSongsProvider re-fetches when authStateProvider changes userId',
      () async {
    final user1 = MockUser();
    final user2 = MockUser();
    when(() => user1.id).thenReturn('user-1');
    when(() => user2.id).thenReturn('user-2');

    when(() => mockHistoryRepo.getRecentSongs('user-1'))
        .thenAnswer((_) async => [tSong(id: 'song-1', title: 'User 1 Song')]);
    when(() => mockHistoryRepo.getRecentSongs('user-2'))
        .thenAnswer((_) async => [tSong(id: 'song-2', title: 'User 2 Song')]);

    final container = ProviderContainer.test(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockClient),
        historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
        authStateProvider.overrideWith((ref) => authController.stream),
      ],
    );
    addTearDown(container.dispose);
    container.listen(recentSongsProvider, (_, __) {});

    authController.add(
      AuthState(AuthChangeEvent.signedIn, _FakeSession(user1)),
    );
    await pumpEventQueue();
    final firstResult = await container.read(recentSongsProvider.future);
    expect(firstResult.single.title, 'User 1 Song');

    authController.add(
      AuthState(AuthChangeEvent.signedIn, _FakeSession(user2)),
    );
    await pumpEventQueue();
    final secondResult = await container.read(recentSongsProvider.future);
    expect(secondResult.single.title, 'User 2 Song');

    verify(() => mockHistoryRepo.getRecentSongs('user-1')).called(1);
    verify(() => mockHistoryRepo.getRecentSongs('user-2')).called(1);
  });
}

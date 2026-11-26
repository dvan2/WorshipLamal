import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/profile/data/repositories/auth_repository.dart';
import 'package:worship_lamal/features/profile/presentation/login_screen.dart';
import 'package:worship_lamal/features/profile/presentation/providers/auth_provider.dart';

import '../../../helpers/mocks.dart';

Future<void> _pumpLoginScreen(
  WidgetTester tester, {
  required MockAuthRepository mockRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Open Login'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open Login'));
  await tester.pumpAndSettle();
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('LoginScreen', () {
    testWidgets('renders email, password fields and Sign In button', (
      tester,
    ) async {
      await _pumpLoginScreen(tester, mockRepo: mockRepo);

      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('signs in with trimmed credentials and pops on success', (
      tester,
    ) async {
      when(() => mockRepo.signIn(any(), any())).thenAnswer((_) async {});

      await _pumpLoginScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        '  user@example.com  ',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.signIn('user@example.com', 'secret123')).called(1);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('Open Login'), findsOneWidget);
    });

    testWidgets('shows error SnackBar and stays on screen when signIn throws', (
      tester,
    ) async {
      when(() => mockRepo.signIn(any(), any()))
          .thenThrow(const AuthException('Invalid login credentials'));

      await _pumpLoginScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'wrongpass',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('Login Failed:'), findsOneWidget);
    });

    testWidgets('disposes controllers cleanly when popped', (tester) async {
      await _pumpLoginScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows validation SnackBar when email or password is empty', (
      tester,
    ) async {
      await _pumpLoginScreen(tester, mockRepo: mockRepo);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your email and password.'),
        findsOneWidget,
      );
      verifyNever(() => mockRepo.getGuestDataSummary());
      verifyNever(() => mockRepo.signIn(any(), any()));
    });

    testWidgets(
        'warns guest with existing data and aborts when Cancel is tapped', (
      tester,
    ) async {
      final guestUser = MockUser();
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => mockRepo.currentUser).thenReturn(guestUser);
      when(() => mockRepo.getGuestDataSummary()).thenAnswer(
        (_) async => const GuestDataSummary(
          hasSetlists: true,
          hasFavorites: true,
        ),
      );

      await _pumpLoginScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Switch Away From Guest Session?'), findsOneWidget);
      expect(find.textContaining('setlists, favorites'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepo.signIn(any(), any()));
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('proceeds with signIn when guest confirms Continue Sign In', (
      tester,
    ) async {
      final guestUser = MockUser();
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => mockRepo.currentUser).thenReturn(guestUser);
      when(() => mockRepo.getGuestDataSummary()).thenAnswer(
        (_) async => const GuestDataSummary(hasUserKeys: true),
      );
      when(() => mockRepo.signIn(any(), any())).thenAnswer((_) async {});

      await _pumpLoginScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Sign In'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.signIn('user@example.com', 'secret123')).called(1);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('signs in directly without dialog when guest has no data', (
      tester,
    ) async {
      final guestUser = MockUser();
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => mockRepo.currentUser).thenReturn(guestUser);
      when(() => mockRepo.getGuestDataSummary())
          .thenAnswer((_) async => const GuestDataSummary());
      when(() => mockRepo.signIn(any(), any())).thenAnswer((_) async {});

      await _pumpLoginScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Switch Away From Guest Session?'), findsNothing);
      verify(() => mockRepo.signIn('user@example.com', 'secret123')).called(1);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets(
        'does not block signIn when getGuestDataSummary throws network error',
        (tester) async {
      final guestUser = MockUser();
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => mockRepo.currentUser).thenReturn(guestUser);
      when(() => mockRepo.getGuestDataSummary())
          .thenThrow(Exception('network error'));
      when(() => mockRepo.signIn(any(), any())).thenAnswer((_) async {});

      await _pumpLoginScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.signIn('user@example.com', 'secret123')).called(1);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('renders Continue with Google button and calls signInWithGoogle',
        (tester) async {
      when(() => mockRepo.signInWithGoogle()).thenAnswer((_) async {});

      await _pumpLoginScreen(tester, mockRepo: mockRepo);

      expect(find.text('Continue with Google'), findsOneWidget);
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.signInWithGoogle()).called(1);
    });
  });
}

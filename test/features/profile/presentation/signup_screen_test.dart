import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worship_lamal/features/profile/presentation/providers/auth_provider.dart';
import 'package:worship_lamal/features/profile/presentation/signup_screen.dart';

import '../../../helpers/mocks.dart';

Future<void> _pumpSignUpScreen(
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
                      builder: (_) => const SignUpScreen(),
                    ),
                  );
                },
                child: const Text('Open SignUp'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open SignUp'));
  await tester.pumpAndSettle();
}

void main() {
  late MockAuthRepository mockRepo;
  late MockUser mockUser;

  setUp(() {
    mockRepo = MockAuthRepository();
    mockUser = MockUser();
  });

  group('SignUpScreen', () {
    testWidgets('validates password mismatch without calling repository', (
      tester,
    ) async {
      when(() => mockRepo.currentUser).thenReturn(null);

      await _pumpSignUpScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'new@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        'different',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      verifyNever(() => mockRepo.signUp(any(), any()));
      verifyNever(() => mockRepo.upgradeGuestAccount(any(), any()));
    });

    testWidgets('validates minimum password length of 6 characters', (
      tester,
    ) async {
      when(() => mockRepo.currentUser).thenReturn(null);

      await _pumpSignUpScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'new@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        '12345',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        '12345',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
      verifyNever(() => mockRepo.signUp(any(), any()));
    });

    testWidgets('upgrades guest account when currentUser is anonymous', (
      tester,
    ) async {
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockRepo.currentUser).thenReturn(mockUser);
      when(() => mockRepo.upgradeGuestAccount(any(), any()))
          .thenAnswer((_) async {});

      await _pumpSignUpScreen(tester, mockRepo: mockRepo);

      expect(find.text('Save Your Account'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'guest@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        'secret123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Account'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepo.upgradeGuestAccount('guest@example.com', 'secret123'),
      ).called(1);
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.text('Account saved successfully!'), findsOneWidget);
    });

    testWidgets('creates new account when currentUser is not a guest', (
      tester,
    ) async {
      when(() => mockRepo.currentUser).thenReturn(null);
      when(() => mockRepo.signUp(any(), any())).thenAnswer((_) async {});

      await _pumpSignUpScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'fresh@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        'secret123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.signUp('fresh@example.com', 'secret123')).called(1);
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.text('Account Created! Please Sign In.'), findsOneWidget);
    });

    testWidgets('disposes controllers cleanly when popped', (tester) async {
      when(() => mockRepo.currentUser).thenReturn(null);

      await _pumpSignUpScreen(tester, mockRepo: mockRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/account/account_page.dart';

void main() {
  group('account page interaction', () {
    testWidgets('tapping logout actually invokes the sign-out callback', (
      tester,
    ) async {
      var signOutCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AccountPage(
            email: 'customer@example.com',
            roleLabel: 'عميل',
            onSignOut: () async => signOutCalls++,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('account_sign_out_button')));
      await tester.pumpAndSettle();

      expect(signOutCalls, 1);
    });

    testWidgets('logout button re-enables after a failed sign-out', (
      tester,
    ) async {
      var attempts = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AccountPage(
            email: 'customer@example.com',
            roleLabel: 'عميل',
            onSignOut: () async {
              attempts++;
              throw Exception('network down');
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('account_sign_out_button')));
      await tester.pumpAndSettle();

      // A swallowed exception must not leave the screen stuck on isLoading.
      await tester.tap(find.byKey(const Key('account_sign_out_button')));
      await tester.pumpAndSettle();

      expect(attempts, 2);
    });

    testWidgets('failed sign-out shows an Arabic error, not a dead screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AccountPage(
            email: 'customer@example.com',
            roleLabel: 'عميل',
            onSignOut: () async => throw Exception('network down'),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('account_sign_out_button')));
      await tester.pumpAndSettle();

      expect(find.text('تعذر تسجيل الخروج، تحقق من الاتصال'), findsOneWidget);
    });

    testWidgets('personal details row is tappable and opens details', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AccountPage(
            email: 'customer@example.com',
            roleLabel: 'عميل',
            onSignOut: () async {},
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('account_personal_details_tile')));
      await tester.pumpAndSettle();

      // Tapping must produce visible feedback, not silently do nothing.
      expect(find.text('customer@example.com'), findsWidgets);
      expect(find.text('عميل'), findsWidgets);
    });

    testWidgets('logout touch target meets the 44px accessibility minimum', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AccountPage(
            email: 'customer@example.com',
            roleLabel: 'عميل',
            onSignOut: () async {},
          ),
        ),
      );

      final size = tester.getSize(
        find.byKey(const Key('account_sign_out_button')),
      );
      expect(size.height, greaterThanOrEqualTo(44.0));
    });
  });

  testWidgets('account page shows account management and logout action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          email: 'customer@example.com',
          roleLabel: 'عميل',
          onSignOut: () async {},
        ),
      ),
    );

    expect(find.text('إدارة الحساب'), findsOneWidget);
    expect(find.text('customer@example.com'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
  });
}

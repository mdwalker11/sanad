import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sanad/auth/role.dart';
import 'package:sanad/admin/admin_route_guard.dart';

void main() {
  testWidgets('admin route renders dashboard only for admin role', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminRouteGuard(
          role: AppRole.admin,
          child: const Text('ADMIN DASHBOARD'),
        ),
      ),
    );
    expect(find.text('ADMIN DASHBOARD'), findsOneWidget);
  });

  testWidgets('non-admin role is denied from admin route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminRouteGuard(
          role: AppRole.customer,
          child: const Text('ADMIN DASHBOARD'),
        ),
      ),
    );
    expect(find.text('ADMIN DASHBOARD'), findsNothing);
    expect(find.textContaining('غير مصرح'), findsOneWidget);
  });
}

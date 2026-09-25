import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_admin/main.dart';

void main() {
  testWidgets('admin app fails closed without Supabase configuration', (
    tester,
  ) async {
    await tester.pumpWidget(const SanadAdminApp(supabaseConfigured: false));
    expect(find.text('إعدادات لوحة الإدارة غير مكتملة.'), findsOneWidget);
  });
}

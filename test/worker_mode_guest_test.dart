import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/main.dart';

void main() {
  testWidgets('guest sees worker mode entry and prompts for sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(const SanadApp());
    await tester.pumpAndSettle();

    expect(find.text('وضع العامل'), findsOneWidget);
    await tester.tap(find.text('وضع العامل'));
    await tester.pumpAndSettle();

    expect(find.text('سجّل الدخول للوصول إلى وضع العامل'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/main.dart';

void main() {
  testWidgets(
    'production app does not expose guest home when Supabase is missing',
    (tester) async {
      await tester.pumpWidget(
        const SanadApp(supabaseConfigured: false, previewMode: false),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('تعذر تشغيل سند الآن'), findsOneWidget);
      expect(find.text('تنظيف المنزل'), findsNothing);
    },
  );
}

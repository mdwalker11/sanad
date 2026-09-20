import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/config/app_config.dart';

void main() {
  test('Supabase configuration accepts a project URL and publishable key', () {
    const config = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: 'sb_publishable_test',
    );

    expect(config.isValid, isTrue);
  });

  test('Supabase configuration rejects incomplete values', () {
    const config = AppConfig(supabaseUrl: '', supabasePublishableKey: '');

    expect(config.isValid, isFalse);
  });
}

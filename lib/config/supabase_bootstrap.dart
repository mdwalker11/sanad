import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static Future<bool> initialize(AppConfig config) async {
    if (!config.isValid) return false;
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    return true;
  }
}

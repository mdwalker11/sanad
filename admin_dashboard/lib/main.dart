import 'package:flutter/material.dart';

import 'package:sanad/config/app_config.dart';
import 'package:sanad/config/supabase_bootstrap.dart';

import 'admin_session_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final configured = await SupabaseBootstrap.initialize(config);
  runApp(SanadAdminApp(supabaseConfigured: configured));
}

class SanadAdminApp extends StatelessWidget {
  const SanadAdminApp({super.key, required this.supabaseConfigured});
  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سند — لوحة الإدارة',
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF164C3B),
      ),
      home: supabaseConfigured
          ? const AdminSessionGate()
          : const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Center(child: Text('إعدادات لوحة الإدارة غير مكتملة.')),
              ),
            ),
    );
  }
}

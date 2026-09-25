import 'package:flutter/material.dart';

import 'package:sanad/auth/role.dart';
import 'package:sanad/auth/role_repository.dart';
import 'package:sanad/operations/operator_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_login.dart';

import 'admin_route_guard.dart';

class AdminSessionGate extends StatelessWidget {
  const AdminSessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return AdminLoginPage(client: Supabase.instance.client);
        }
        return FutureBuilder<AppRole>(
          future: RoleRepository(Supabase.instance.client).currentRole(),
          builder: (context, role) {
            if (role.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return AdminRouteGuard(
              role: role.data ?? AppRole.customer,
              child: const OperatorPage(),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../auth/role.dart';

class AdminRouteGuard extends StatelessWidget {
  const AdminRouteGuard({super.key, required this.role, required this.child});

  final AppRole role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (role != AppRole.admin) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: Text('غير مصرح بالوصول إلى لوحة الإدارة')),
        ),
      );
    }
    return child;
  }
}

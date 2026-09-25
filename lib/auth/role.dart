enum AppRole { customer, worker, admin }

AppRole resolvePrimaryRole(Iterable<String> roles) {
  final normalized = roles.map((role) => role.toLowerCase()).toSet();
  if (normalized.contains('admin') || normalized.contains('operator')) {
    return AppRole.admin;
  }
  if (normalized.contains('worker')) return AppRole.worker;
  return AppRole.customer;
}

String roleLabel(AppRole role) => switch (role) {
  AppRole.customer => 'عميل',
  AppRole.worker => 'مقدم خدمة',
  AppRole.admin => 'مشرف تشغيل',
};

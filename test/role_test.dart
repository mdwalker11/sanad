import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/auth/role.dart';

void main() {
  test('role priority is deterministic', () {
    expect(resolvePrimaryRole(['customer', 'worker', 'admin']), AppRole.admin);
    expect(resolvePrimaryRole(['worker', 'customer']), AppRole.worker);
    expect(resolvePrimaryRole(['customer']), AppRole.customer);
    expect(resolvePrimaryRole(['unknown']), AppRole.customer);
  });

  test('role labels are Arabic and distinct', () {
    expect(roleLabel(AppRole.customer), 'عميل');
    expect(roleLabel(AppRole.worker), 'مقدم خدمة');
    expect(roleLabel(AppRole.admin), 'مشرف تشغيل');
  });
}

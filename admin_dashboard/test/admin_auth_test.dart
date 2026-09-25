import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_admin/admin_login.dart';

void main() {
  test('admin login validation rejects incomplete credentials', () {
    expect(validateAdminLogin('', 'short'), isNotNull);
    expect(validateAdminLogin('admin@example.com', '123456'), isNull);
  });
}

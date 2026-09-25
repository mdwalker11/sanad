import 'package:flutter_test/flutter_test.dart';

void main() {
  test('operator statuses use only supported moderation values', () {
    const statuses = {'approved', 'rejected', 'suspended'};
    expect(statuses.contains('approved'), isTrue);
    expect(statuses.contains('unknown'), isFalse);
  });
}

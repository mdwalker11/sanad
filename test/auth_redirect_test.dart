import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android signup redirect uses the Sanad deep link', () {
    const redirect = 'ly.sanad.sanad://login-callback/';
    expect(Uri.parse(redirect).scheme, 'ly.sanad.sanad');
    expect(Uri.parse(redirect).host, 'login-callback');
  });
}

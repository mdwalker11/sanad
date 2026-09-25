import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/order_media_repository.dart';

void main() {
  test('media paths are scoped to the uploader and order', () {
    final path = mediaStoragePath(
      userId: 'user-1',
      orderId: 'order-1',
      extension: '.JPG',
      timestamp: 123,
    );
    expect(path, 'user-1/order-1/123.jpg');
  });

  test('empty media is rejected before upload', () {
    expect(
      () => validateMedia(Uint8List(0), 'jpg'),
      throwsA(isA<MediaUploadException>()),
    );
  });
}

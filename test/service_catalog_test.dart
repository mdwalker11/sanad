import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/catalog/service_catalog.dart';

void main() {
  test('service catalog preserves database id and display order', () {
    final catalog = ServiceCatalog.fromRows([
      {
        'id': 'service-2',
        'slug': 'plumbing',
        'name_ar': 'السباكة',
        'description_ar': 'حلول سريعة',
        'sort_order': 3,
      },
      {
        'id': 'service-1',
        'slug': 'home-cleaning',
        'name_ar': 'تنظيف المنزل',
        'description_ar': null,
        'sort_order': 1,
      },
    ]);

    expect(catalog.items.map((item) => item.id), ['service-1', 'service-2']);
    expect(catalog.items.first.description, 'خدمات منزلية موثوقة');
  });
}

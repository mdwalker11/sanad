import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/catalog/service_catalog.dart';

void main() {
  test('service catalog parses Supabase rows in display order', () {
    final catalog = ServiceCatalog.fromRows([
      {
        'slug': 'plumbing',
        'name_ar': 'السباكة',
        'description_ar': 'حلول سريعة',
        'sort_order': 3,
      },
      {
        'slug': 'home-cleaning',
        'name_ar': 'تنظيف المنزل',
        'description_ar': null,
        'sort_order': 1,
      },
    ]);

    expect(catalog.items.map((item) => item.slug), [
      'home-cleaning',
      'plumbing',
    ]);
    expect(catalog.items.first.description, 'خدمات منزلية موثوقة');
  });
}

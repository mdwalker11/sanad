class ServiceCatalogItem {
  const ServiceCatalogItem({
    required this.slug,
    required this.name,
    required this.description,
    required this.sortOrder,
  });

  final String slug;
  final String name;
  final String description;
  final int sortOrder;
}

class ServiceCatalog {
  const ServiceCatalog(this.items);

  final List<ServiceCatalogItem> items;

  factory ServiceCatalog.fromRows(List<Map<String, dynamic>> rows) {
    final items = rows.map((row) {
      return ServiceCatalogItem(
        slug: row['slug'] as String,
        name: row['name_ar'] as String,
        description: (row['description_ar'] as String?)?.trim().isNotEmpty == true
            ? row['description_ar'] as String
            : 'خدمات منزلية موثوقة',
        sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ServiceCatalog(items);
  }
}

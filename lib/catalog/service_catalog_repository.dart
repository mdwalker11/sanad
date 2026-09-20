import 'package:supabase_flutter/supabase_flutter.dart';

import 'service_catalog.dart';

class ServiceCatalogRepository {
  const ServiceCatalogRepository(this.client);

  final SupabaseClient client;

  Future<ServiceCatalog> fetchActive() async {
    final rows = await client
        .from('service_categories')
        .select('id, slug, name_ar, description_ar, sort_order')
        .eq('is_active', true)
        .order('sort_order');
    return ServiceCatalog.fromRows(
      rows.map((row) => Map<String, dynamic>.from(row)).toList(),
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintException implements Exception {
  const ComplaintException(this.message);
  final String message;

  @override
  String toString() => 'ComplaintException: $message';
}

class ComplaintDraft {
  ComplaintDraft({
    required this.orderId,
    required this.openedBy,
    required this.category,
    required this.description,
  }) {
    if (orderId.trim().isEmpty || openedBy.trim().isEmpty) {
      throw const ComplaintException('بيانات الشكوى ناقصة');
    }
    if (category.trim().isEmpty || description.trim().isEmpty) {
      throw const ComplaintException('يرجى اختيار التصنيف وكتابة التفاصيل');
    }
    if (description.trim().length > 2000) {
      throw const ComplaintException('تفاصيل الشكوى طويلة جدًا');
    }
  }

  final String orderId;
  final String openedBy;
  final String category;
  final String description;

  Map<String, dynamic> toInsertMap() => {
    'order_id': orderId,
    'opened_by': openedBy,
    'category': category.trim(),
    'description': description.trim(),
  };
}

class ComplaintRepository {
  const ComplaintRepository(this.client);
  final SupabaseClient client;

  Future<void> submit(ComplaintDraft complaint) async {
    await client
        .from('complaints')
        .insert(complaint.toInsertMap())
        .select()
        .single();
  }
}

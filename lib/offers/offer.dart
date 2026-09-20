class OfferException implements Exception {
  const OfferException(this.message);
  final String message;

  @override
  String toString() => 'OfferException: $message';
}

class ServiceOfferDraft {
  ServiceOfferDraft({
    required this.orderId,
    required this.workerId,
    required this.totalAmount,
    this.visitAmount = 0,
    this.laborAmount = 0,
    this.materialsAmount = 0,
    this.estimatedArrivalMinutes,
    this.estimatedDurationMinutes,
    this.includes,
    this.excludes,
    this.warrantyText,
  }) {
    if (orderId.trim().isEmpty || workerId.trim().isEmpty) {
      throw const OfferException('بيانات الطلب أو العامل ناقصة');
    }
    if ([
      totalAmount,
      visitAmount,
      laborAmount,
      materialsAmount,
    ].any((amount) => amount < 0)) {
      throw const OfferException('لا يمكن أن تكون مبالغ العرض سالبة');
    }
    if (totalAmount == 0) {
      throw const OfferException('يرجى إدخال قيمة العرض');
    }
  }

  final String orderId;
  final String workerId;
  final double totalAmount;
  final double visitAmount;
  final double laborAmount;
  final double materialsAmount;
  final int? estimatedArrivalMinutes;
  final int? estimatedDurationMinutes;
  final String? includes;
  final String? excludes;
  final String? warrantyText;

  Map<String, dynamic> toInsertMap() => {
    'order_id': orderId,
    'worker_id': workerId,
    'total_amount': totalAmount,
    'visit_amount': visitAmount,
    'labor_amount': laborAmount,
    'materials_amount': materialsAmount,
    'commission_rate': 20.0,
    if (estimatedArrivalMinutes != null)
      'estimated_arrival_minutes': estimatedArrivalMinutes,
    if (estimatedDurationMinutes != null)
      'estimated_duration_minutes': estimatedDurationMinutes,
    if (includes != null) 'includes': includes,
    if (excludes != null) 'excludes': excludes,
    if (warrantyText != null) 'warranty_text': warrantyText,
    'status': 'pending',
  };
}

class OrderStatusLabel {
  const OrderStatusLabel(this.value, this.label);

  final String value;
  final String label;

  factory OrderStatusLabel.fromValue(String value) {
    const labels = {
      'new': 'جديد',
      'under_review': 'قيد المراجعة',
      'awaiting_offers': 'بانتظار عروض العاملين',
      'offer_selected': 'تم اختيار العرض',
      'confirmed': 'تم تأكيد العامل',
      'on_the_way': 'العامل في الطريق',
      'in_progress': 'الخدمة جارية',
      'awaiting_extra_approval': 'بانتظار اعتماد تكلفة إضافية',
      'awaiting_completion': 'بانتظار تأكيد الإنجاز',
      'completed': 'اكتملت الخدمة',
      'awaiting_payment': 'بانتظار الدفع',
      'paid': 'تم الدفع',
      'awaiting_review': 'بانتظار التقييم',
      'disputed': 'شكوى قيد المراجعة',
      'warranty': 'ضمن الضمان',
      'closed': 'مغلق',
      'cancelled': 'ملغى',
    };
    return OrderStatusLabel(value, labels[value] ?? 'قيد المتابعة');
  }
}

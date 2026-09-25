class ReviewException implements Exception {
  const ReviewException(this.message);
  final String message;

  @override
  String toString() => 'ReviewException: $message';
}

class ReviewDraft {
  ReviewDraft({
    required this.orderId,
    required this.customerId,
    required this.workerId,
    required this.rating,
    this.comment,
  }) {
    if (orderId.trim().isEmpty ||
        customerId.trim().isEmpty ||
        workerId.trim().isEmpty) {
      throw const ReviewException('بيانات التقييم ناقصة');
    }
    if (rating < 1 || rating > 5) {
      throw const ReviewException('التقييم يجب أن يكون بين نجمة و5 نجوم');
    }
    if (comment != null && comment!.trim().length > 1000) {
      throw const ReviewException('التعليق طويل جدًا');
    }
  }

  final String orderId;
  final String customerId;
  final String workerId;
  final int rating;
  final String? comment;

  Map<String, dynamic> toInsertMap() => {
    'order_id': orderId,
    'customer_id': customerId,
    'worker_id': workerId,
    'rating': rating,
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
  };
}

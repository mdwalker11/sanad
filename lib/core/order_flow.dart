enum BookingType { scheduled, timeWindow, immediate }

enum OrderStatus { newOrder, awaitingOffers, confirmed, completed, cancelled }

enum OfferStatus { pending, accepted, rejected }

class OrderFlowException implements Exception {
  const OrderFlowException(this.message);
  final String message;

  @override
  String toString() => 'OrderFlowException: $message';
}

class ServiceOrder {
  ServiceOrder({
    required this.id,
    required this.customerId,
    required this.serviceSlug,
    required this.description,
    required this.bookingType,
    this.status = OrderStatus.newOrder,
    this.selectedWorkerId,
  });

  final String id;
  final String customerId;
  final String serviceSlug;
  final String description;
  final BookingType bookingType;
  OrderStatus status;
  String? selectedWorkerId;
}

class ServiceOffer {
  ServiceOffer({
    required this.id,
    required this.orderId,
    required this.workerId,
    required this.totalAmount,
    required this.estimatedArrivalMinutes,
    this.status = OfferStatus.pending,
  });

  final String id;
  final String orderId;
  final String workerId;
  final double totalAmount;
  final int estimatedArrivalMinutes;
  OfferStatus status;
}

class InMemoryOrderRepository {
  final Map<String, ServiceOrder> _orders = {};
  final Map<String, ServiceOffer> _offers = {};
  int _sequence = 0;

  ServiceOrder createOrder({
    required String customerId,
    required String serviceSlug,
    required String description,
    required BookingType bookingType,
  }) {
    final order = ServiceOrder(
      id: 'order-${++_sequence}',
      customerId: customerId,
      serviceSlug: serviceSlug,
      description: description,
      bookingType: bookingType,
      status: OrderStatus.awaitingOffers,
    );
    _orders[order.id] = order;
    return order;
  }

  ServiceOffer submitOffer({
    required String orderId,
    required String workerId,
    required double totalAmount,
    required int estimatedArrivalMinutes,
  }) {
    final order = _requireOrder(orderId);
    if (order.status != OrderStatus.awaitingOffers) {
      throw const OrderFlowException(
        'لا يمكن إرسال عرض لهذا الطلب في حالته الحالية',
      );
    }
    if (totalAmount < 0 || estimatedArrivalMinutes < 0) {
      throw const OrderFlowException('بيانات العرض غير صالحة');
    }
    final offer = ServiceOffer(
      id: 'offer-${++_sequence}',
      orderId: orderId,
      workerId: workerId,
      totalAmount: totalAmount,
      estimatedArrivalMinutes: estimatedArrivalMinutes,
    );
    _offers[offer.id] = offer;
    return offer;
  }

  ServiceOrder acceptOffer(String orderId, String offerId) {
    final order = _requireOrder(orderId);
    final offer = _offers[offerId];
    if (offer == null || offer.orderId != orderId) {
      throw const OrderFlowException('العرض غير موجود لهذا الطلب');
    }
    if (order.status != OrderStatus.awaitingOffers ||
        offer.status != OfferStatus.pending) {
      throw const OrderFlowException('لا يمكن قبول العرض في الحالة الحالية');
    }
    for (final candidate in offersFor(orderId)) {
      candidate.status = candidate.id == offerId
          ? OfferStatus.accepted
          : OfferStatus.rejected;
    }
    order.selectedWorkerId = offer.workerId;
    order.status = OrderStatus.confirmed;
    return order;
  }

  void markCompleted(String orderId) {
    final order = _requireOrder(orderId);
    if (order.status != OrderStatus.confirmed) {
      throw const OrderFlowException('لا يمكن إكمال طلب غير مؤكد');
    }
    order.status = OrderStatus.completed;
  }

  List<ServiceOffer> offersFor(String orderId) => _offers.values
      .where((offer) => offer.orderId == orderId)
      .toList(growable: false);

  ServiceOrder _requireOrder(String id) {
    final order = _orders[id];
    if (order == null) {
      throw const OrderFlowException('الطلب غير موجود');
    }
    return order;
  }
}

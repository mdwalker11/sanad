import 'package:flutter/material.dart';

enum BookingType { scheduled, timeWindow, immediate }

DateTime combineDateAndTime(DateTime date, TimeOfDay time) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);

void validateTimeWindow(DateTime start, DateTime end) {
  if (!end.isAfter(start)) {
    throw const OrderRequestException('نهاية الموعد يجب أن تكون بعد بدايته');
  }
}

class OrderRequestException implements Exception {
  const OrderRequestException(this.message);
  final String message;

  @override
  String toString() => 'OrderRequestException: $message';
}

class OrderRequest {
  OrderRequest({
    required this.customerId,
    required this.serviceId,
    this.addressId,
    required this.description,
    required this.bookingType,
    this.preferredStart,
    this.preferredEnd,
  }) {
    if (customerId.trim().isEmpty || serviceId.trim().isEmpty) {
      throw const OrderRequestException('بيانات المستخدم أو الخدمة ناقصة');
    }
    if (description.trim().isEmpty) {
      throw const OrderRequestException('يرجى وصف الخدمة المطلوبة');
    }
    if (bookingType == BookingType.timeWindow &&
        (preferredStart == null || preferredEnd == null)) {
      throw const OrderRequestException('يرجى تحديد الفترة الزمنية');
    }
    if (bookingType == BookingType.scheduled &&
        (preferredStart == null || preferredEnd == null)) {
      throw const OrderRequestException('يرجى تحديد الموعد');
    }
    if (preferredStart != null &&
        preferredEnd != null &&
        !preferredEnd!.isAfter(preferredStart!)) {
      throw const OrderRequestException('نهاية الموعد يجب أن تكون بعد بدايته');
    }
  }

  final String customerId;
  final String serviceId;
  final String? addressId;
  final String description;
  final BookingType bookingType;
  final DateTime? preferredStart;
  final DateTime? preferredEnd;

  Map<String, dynamic> toInsertMap() {
    return {
      'customer_id': customerId,
      'service_id': serviceId,
      if (addressId != null) 'address_id': addressId,
      'description': description.trim(),
      'booking_type': bookingType.name,
      'status': 'awaiting_offers',
      if (preferredStart != null)
        'preferred_start': preferredStart!.toUtc().toIso8601String(),
      if (preferredEnd != null)
        'preferred_end': preferredEnd!.toUtc().toIso8601String(),
    };
  }
}

import 'package:flutter/material.dart';

import 'order_request.dart';
import 'order_repository.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.customerId,
    required this.repository,
  });

  final String serviceId;
  final String serviceName;
  final String customerId;
  final OrderSink repository;

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _description = TextEditingController();
  final _address = TextEditingController();
  BookingType _bookingType = BookingType.immediate;
  DateTime? _preferredStart;
  DateTime? _preferredEnd;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // الحارس الأول: يمنع الضغط المزدوج على شبكة بطيئة من إنشاء طلبين.
    // لا يكفي `onPressed: _saving ? null : _submit` وحده، لأن إعادة البناء
    // لا تحدث قبل أن يبدأ الاستدعاء غير المتزامن.
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // التحقق يسبق أي كتابة: بناء الطلب أولاً يضمن ألا نترك عنواناً
      // يتيماً في قاعدة البيانات عندما يكون الوصف فارغاً.
      OrderRequest(
        customerId: widget.customerId,
        serviceId: widget.serviceId,
        description: _description.text,
        bookingType: _bookingType,
        preferredStart: _preferredStart,
        preferredEnd: _preferredEnd,
      );

      final addressText = _address.text.trim();
      String? addressId;
      if (addressText.isNotEmpty) {
        final address = await widget.repository.createAddress(
          customerId: widget.customerId,
          addressText: addressText,
        );
        addressId = address['id'] as String?;
      }

      final request = OrderRequest(
        customerId: widget.customerId,
        serviceId: widget.serviceId,
        description: _description.text,
        addressId: addressId,
        bookingType: _bookingType,
        preferredStart: _preferredStart,
        preferredEnd: _preferredEnd,
      );
      await widget.repository.createOrder(request);
      if (mounted) Navigator.pop(context, true);
    } on OrderRequestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر إنشاء الطلب، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('طلب ${widget.serviceName}')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _description,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'وصف المطلوب',
                hintText: 'اكتب التفاصيل بوضوح',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'العنوان أو المنطقة',
                hintText: 'مثال: طرابلس - حي الأندلس',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'نوع الموعد',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButtonFormField<BookingType>(
              initialValue: _bookingType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                  value: BookingType.immediate,
                  child: Text('طلب فوري'),
                ),
                DropdownMenuItem(
                  value: BookingType.scheduled,
                  child: Text('موعد محدد'),
                ),
                DropdownMenuItem(
                  value: BookingType.timeWindow,
                  child: Text('فترة زمنية'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _bookingType = value);
              },
            ),
            if (_bookingType != BookingType.immediate) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    initialDate: _preferredStart ?? DateTime.now(),
                  );
                  if (picked == null || !mounted) return;
                  setState(() {
                    _selectedDate = picked;
                    _startTime ??= const TimeOfDay(hour: 9, minute: 0);
                    _endTime ??= const TimeOfDay(hour: 11, minute: 0);
                    _preferredStart = combineDateAndTime(picked, _startTime!);
                    _preferredEnd = combineDateAndTime(picked, _endTime!);
                  });
                },
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _selectedDate == null
                      ? 'اختر اليوم والوقت'
                      : 'اليوم: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectedDate == null
                          ? null
                          : () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime:
                                    _startTime ??
                                    const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (time == null || !mounted) return;
                              setState(() {
                                _startTime = time;
                                _preferredStart = combineDateAndTime(
                                  _selectedDate!,
                                  time,
                                );
                              });
                            },
                      child: Text(
                        _startTime == null
                            ? 'وقت البداية'
                            : 'من ${_startTime!.format(context)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectedDate == null
                          ? null
                          : () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime:
                                    _endTime ??
                                    const TimeOfDay(hour: 11, minute: 0),
                              );
                              if (time == null || !mounted) return;
                              setState(() {
                                _endTime = time;
                                _preferredEnd = combineDateAndTime(
                                  _selectedDate!,
                                  time,
                                );
                              });
                            },
                      child: Text(
                        _endTime == null
                            ? 'وقت النهاية'
                            : 'إلى ${_endTime!.format(context)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('create_order_submit'),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('إنشاء الطلب'),
            ),
          ],
        ),
      ),
    );
  }
}

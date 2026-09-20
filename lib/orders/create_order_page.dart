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
  final OrderRepository repository;

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _description = TextEditingController();
  BookingType _bookingType = BookingType.immediate;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      final request = OrderRequest(
        customerId: widget.customerId,
        serviceId: widget.serviceId,
        description: _description.text,
        bookingType: _bookingType,
      );
      setState(() {
        _saving = true;
        _error = null;
      });
      await widget.repository.createOrder(request);
      if (mounted) Navigator.pop(context, true);
    } on OrderRequestException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'تعذر إنشاء الطلب، حاول مرة أخرى');
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
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

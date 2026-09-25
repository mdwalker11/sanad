import 'package:flutter/material.dart';

import 'complaint.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({
    super.key,
    required this.orderId,
    required this.openedBy,
    required this.repository,
  });

  final String orderId;
  final String openedBy;
  final ComplaintRepository repository;

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _description = TextEditingController();
  String _category = 'جودة الخدمة';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      final complaint = ComplaintDraft(
        orderId: widget.orderId,
        openedBy: widget.openedBy,
        category: _category,
        description: _description.text,
      );
      setState(() {
        _saving = true;
        _error = null;
      });
      await widget.repository.submit(complaint);
      if (mounted) Navigator.pop(context, true);
    } on ComplaintException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'تعذر إرسال الشكوى');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('فتح شكوى')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'سنراجع شكواك ونتواصل معك عند الحاجة.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'تصنيف الشكوى',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'جودة الخدمة',
                child: Text('جودة الخدمة'),
              ),
              DropdownMenuItem(
                value: 'التزام العامل',
                child: Text('التزام العامل'),
              ),
              DropdownMenuItem(
                value: 'السعر أو الدفع',
                child: Text('السعر أو الدفع'),
              ),
              DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _description,
            maxLines: 7,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'تفاصيل الشكوى *',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('إرسال الشكوى'),
          ),
        ],
      ),
    ),
  );
}

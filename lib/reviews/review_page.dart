import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'review.dart';

class ReviewRepository {
  const ReviewRepository(this.client);
  final SupabaseClient client;

  Future<void> submit(ReviewDraft review) async {
    await client.from('reviews').insert(review.toInsertMap()).select().single();
  }
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.workerId,
    required this.repository,
  });

  final String orderId;
  final String customerId;
  final String workerId;
  final ReviewRepository repository;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      final review = ReviewDraft(
        orderId: widget.orderId,
        customerId: widget.customerId,
        workerId: widget.workerId,
        rating: _rating,
        comment: _comment.text,
      );
      setState(() {
        _saving = true;
        _error = null;
      });
      await widget.repository.submit(review);
      if (mounted) Navigator.pop(context, true);
    } on ReviewException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'تعذر إرسال التقييم');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('قيّم الخدمة')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'كيف كانت تجربتك مع العامل؟',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                tooltip: '$value نجوم',
                onPressed: () => setState(() => _rating = value),
                icon: Icon(
                  value <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 42,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'تعليق اختياري',
              hintText: 'شاركنا ملاحظتك',
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
                : const Text('إرسال التقييم'),
          ),
        ],
      ),
    ),
  );
}

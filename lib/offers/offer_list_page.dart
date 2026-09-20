import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'offer_repository.dart';

class OfferListPage extends StatefulWidget {
  const OfferListPage({
    super.key,
    required this.orderId,
    required this.repository,
  });

  final String orderId;
  final WorkerOfferRepository repository;

  @override
  State<OfferListPage> createState() => _OfferListPageState();
}

class _OfferListPageState extends State<OfferListPage> {
  late Future<List<Map<String, dynamic>>> _offers;
  String? _accepting;

  @override
  void initState() {
    super.initState();
    _offers = widget.repository.offersForOrder(widget.orderId);
  }

  Future<void> _accept(String offerId) async {
    setState(() => _accepting = offerId);
    try {
      await Supabase.instance.client.rpc(
        'accept_service_offer',
        params: {'p_order_id': widget.orderId, 'p_offer_id': offerId},
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر قبول العرض')));
      }
    } finally {
      if (mounted) setState(() => _accepting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عروض العاملين')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _offers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final offers = snapshot.data ?? const <Map<String, dynamic>>[];
            if (offers.isEmpty) {
              return const Center(child: Text('لم تصل عروض بعد'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final offer = offers[index];
                final id = offer['id'] as String;
                final amount = offer['total_amount'];
                final arrival = offer['estimated_arrival_minutes'];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '$amount د.ل',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text('الوصول المتوقع: $arrival دقيقة'),
                        if (offer['includes'] != null)
                          Text('يشمل: ${offer['includes']}'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _accepting == null
                              ? () => _accept(id)
                              : null,
                          child: _accepting == id
                              ? const CircularProgressIndicator()
                              : const Text('قبول العرض'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

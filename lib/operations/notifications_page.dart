import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'operations_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.userId});
  final String userId;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return OperationsRepository(
      Supabase.instance.client,
    ).notifications(widget.userId);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('تعذر تحميل الإشعارات'));
          }
          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('لا توجد إشعارات بعد')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final readAt = item['read_at'];
                return Card(
                  child: ListTile(
                    onTap: readAt == null
                        ? () async {
                            await OperationsRepository(
                              Supabase.instance.client,
                            ).markNotificationRead(item['id'] as String);
                            if (mounted) await _refresh();
                          }
                        : null,
                    leading: Icon(
                      readAt == null
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_outlined,
                    ),
                    title: Text(item['title_ar'] as String? ?? 'إشعار'),
                    subtitle: Text(item['body_ar'] as String? ?? ''),
                  ),
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

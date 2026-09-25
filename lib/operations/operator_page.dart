import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OperatorRepository {
  const OperatorRepository(this.client);
  final SupabaseClient client;

  Future<bool> isOperator() async {
    final result = await client.rpc('is_operator');
    return result == true;
  }

  Future<List<Map<String, dynamic>>> pendingWorkers() async {
    final rows = await client
        .from('worker_profiles')
        .select(
          'user_id, bio, years_experience, gender, verification_status, created_at',
        )
        .eq('verification_status', 'pending')
        .order('created_at');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> setWorkerVerification(String workerId, String status) async {
    await client.rpc(
      'operator_set_worker_verification',
      params: {'p_worker_id': workerId, 'p_status': status},
    );
  }

  Future<List<Map<String, dynamic>>> complaints() async {
    final rows = await client
        .from('complaints')
        .select(
          'id, order_id, opened_by, category, description, status, resolution, created_at',
        )
        .order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> resolveComplaint({
    required String complaintId,
    required String status,
    required String resolution,
  }) async {
    await client.rpc(
      'operator_resolve_complaint',
      params: {
        'p_complaint_id': complaintId,
        'p_status': status,
        'p_resolution': resolution,
      },
    );
  }
}

class OperatorPage extends StatefulWidget {
  const OperatorPage({super.key});
  @override
  State<OperatorPage> createState() => _OperatorPageState();
}

class _OperatorPageState extends State<OperatorPage> {
  late final OperatorRepository _repository;
  late Future<bool> _access;
  late Future<List<Map<String, dynamic>>> _workers;
  late Future<List<Map<String, dynamic>>> _complaints;

  @override
  void initState() {
    super.initState();
    _repository = OperatorRepository(Supabase.instance.client);
    _reload();
  }

  void _reload() {
    _access = _repository.isOperator();
    _workers = _repository.pendingWorkers();
    _complaints = _repository.complaints();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_workers, _complaints]);
  }

  Future<void> _approve(String workerId, String status) async {
    try {
      await _repository.setWorkerVerification(workerId, status);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث اعتماد العامل')));
        await _refresh();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر تنفيذ الإجراء')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('لوحة التشغيل')),
      body: FutureBuilder<bool>(
        future: _access,
        builder: (context, accessSnapshot) {
          if (accessSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (accessSnapshot.data != true) {
            return const Center(child: Text('لا تملك صلاحية لوحة التشغيل'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'العاملون بانتظار المراجعة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _workers,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    final items =
                        snapshot.data ?? const <Map<String, dynamic>>[];
                    if (items.isEmpty) {
                      return const ListTile(title: Text('لا توجد ملفات معلقة'));
                    }
                    return Column(
                      children: items
                          .map(
                            (worker) => Card(
                              child: ListTile(
                                title: Text(
                                  worker['bio'] as String? ?? 'بدون نبذة',
                                ),
                                subtitle: Text(
                                  'الخبرة: ${worker['years_experience'] ?? 0} سنوات',
                                ),
                                trailing: Wrap(
                                  children: [
                                    IconButton(
                                      onPressed: () => _approve(
                                        worker['user_id'] as String,
                                        'approved',
                                      ),
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _approve(
                                        worker['user_id'] as String,
                                        'rejected',
                                      ),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'الشكاوى',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _complaints,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    final items =
                        snapshot.data ?? const <Map<String, dynamic>>[];
                    if (items.isEmpty) {
                      return const ListTile(title: Text('لا توجد شكاوى'));
                    }
                    return Column(
                      children: items
                          .map(
                            (item) => Card(
                              child: ListTile(
                                title: Text(
                                  item['category'] as String? ?? 'شكوى',
                                ),
                                subtitle: Text(
                                  item['description'] as String? ?? '',
                                ),
                                trailing: Text(item['status'] as String? ?? ''),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

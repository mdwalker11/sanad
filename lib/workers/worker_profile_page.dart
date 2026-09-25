import 'package:flutter/material.dart';

import 'worker_profile.dart';
import 'worker_repository.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({
    super.key,
    required this.repository,
    required this.userId,
  });

  final WorkerProfileSink repository;
  final String userId;

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  final _bio = TextEditingController();
  final _years = TextEditingController(text: '0');
  String _gender = 'male';
  bool _tools = false;
  bool _transport = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _bio.dispose();
    _years.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    WorkerProfileDraft profile;
    try {
      profile = WorkerProfileDraft(
        userId: widget.userId,
        bio: _bio.text,
        yearsExperience: int.tryParse(_years.text) ?? -1,
        gender: _gender,
        hasTools: _tools,
        hasTransport: _transport,
      );
    } on ArgumentError catch (error) {
      setState(() => _error = error.message?.toString());
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveProfile(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الملف وإرساله للمراجعة')),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر حفظ الملف، تحقق من الاتصال والصلاحيات');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ملف العامل')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'أكمل بياناتك ليتمكن فريق سند من مراجعة ملفك.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bio,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'نبذة وخبرتك *',
                hintText: 'اذكر الخدمات والخبرة التي تقدمها',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _years,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سنوات الخبرة *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'الجنس',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('ذكر')),
                DropdownMenuItem(value: 'female', child: Text('أنثى')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _gender = value);
              },
            ),
            SwitchListTile(
              title: const Text('أمتلك الأدوات'),
              value: _tools,
              onChanged: (value) => setState(() => _tools = value),
            ),
            SwitchListTile(
              title: const Text('أمتلك وسيلة نقل'),
              value: _transport,
              onChanged: (value) => setState(() => _transport = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('حفظ الملف وإرساله للمراجعة'),
            ),
          ],
        ),
      ),
    );
  }
}

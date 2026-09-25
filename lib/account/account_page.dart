import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.email,
    required this.roleLabel,
    required this.onSignOut,
  });

  final String email;
  final String roleLabel;
  final Future<void> Function() onSignOut;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _signingOut = false;
  String? _error;

  Future<void> _signOut() async {
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر تسجيل الخروج، تحقق من الاتصال');
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _showPersonalDetails() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'البيانات الشخصية',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(widget.email),
              const SizedBox(height: 8),
              Text(widget.roleLabel),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('إدارة الحساب')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFDFF3EA),
                    child: Icon(Icons.person_outline, color: Color(0xFF164C3B)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.email,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.roleLabel,
                          style: const TextStyle(color: Color(0xFF4D6B5A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const Key('account_personal_details_tile'),
                  leading: const Icon(Icons.person_outline),
                  title: const Text('البيانات الشخصية'),
                  subtitle: const Text('راجع بيانات حسابك ودورك في سند.'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _showPersonalDetails,
                ),
                const Divider(height: 1),
                const ListTile(
                  key: Key('account_security_tile'),
                  leading: Icon(Icons.lock_reset_outlined),
                  title: Text('الأمان وكلمة المرور'),
                  subtitle: Text('يمكنك استعادة كلمة المرور من شاشة الدخول.'),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              key: const Key('account_error_banner'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFB3261E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB3261E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              key: const Key('account_sign_out_button'),
              onPressed: _signingOut ? null : _signOut,
              icon: _signingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
            ),
          ),
        ],
      ),
    ),
  );
}

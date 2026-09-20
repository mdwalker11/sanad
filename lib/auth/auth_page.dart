import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_form.dart';
import 'auth_repository.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.homeBuilder});

  final WidgetBuilder homeBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        if (session != null) return homeBuilder(context);
        return const SignInPage();
      },
    );
  }
}

class AuthenticatedPlaceholder extends StatelessWidget {
  const AuthenticatedPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('تم تسجيل الدخول إلى سند')));
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _signUp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = AuthForm(email: _email.text, password: _password.text);
    if (!form.isValid ||
        (_signUp &&
            (_name.text.trim().isEmpty || _phone.text.trim().isEmpty))) {
      setState(
        () => _error = form.validationMessage ?? 'أكمل البيانات المطلوبة',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AuthRepository(Supabase.instance.client);
      if (_signUp) {
        await auth.signUp(form: form, fullName: _name.text, phone: _phone.text);
      } else {
        await auth.signIn(form);
      }
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'تعذر إكمال العملية، تحقق من الاتصال والبيانات');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 48),
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFF315D47),
                child: Text(
                  'س',
                  style: TextStyle(color: Colors.white, fontSize: 30),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _signUp ? 'أنشئ حسابك في سند' : 'مرحبًا بك في سند',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _signUp
                    ? 'ابدأ بطلب خدمات منزلية موثوقة.'
                    : 'سجّل الدخول لمتابعة طلباتك.',
              ),
              const SizedBox(height: 28),
              if (_signUp) ...[
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : Text(_signUp ? 'إنشاء الحساب' : 'تسجيل الدخول'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _signUp = !_signUp;
                        _error = null;
                      }),
                child: Text(
                  _signUp
                      ? 'لديك حساب؟ تسجيل الدخول'
                      : 'ليس لديك حساب؟ إنشاء حساب',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_form.dart';
import 'auth_feedback.dart';
import 'auth_repository.dart';
import 'role.dart';
import 'role_repository.dart';
import '../workers/provider_home_page.dart';
import '../orders/customer_home_page.dart';

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
        if (session == null) return const SignInPage();
        return FutureBuilder<AppRole>(
          future: RoleRepository(Supabase.instance.client).currentRole(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (roleSnapshot.hasError) {
              return const RoleUnavailablePage();
            }
            return RoleHomePage(
              role: roleSnapshot.data ?? AppRole.customer,
              homeBuilder: homeBuilder,
            );
          },
        );
      },
    );
  }
}

class RoleHomePage extends StatelessWidget {
  const RoleHomePage({
    super.key,
    required this.role,
    required this.homeBuilder,
  });
  final AppRole role;
  final WidgetBuilder homeBuilder;

  @override
  Widget build(BuildContext context) {
    if (role == AppRole.admin) {
      return const Scaffold(
        body: Center(child: Text('افتح لوحة الإدارة من بوابة الويب.')),
      );
    }
    if (role == AppRole.worker) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return const RoleUnavailablePage();
      return ProviderHomePage(workerId: userId);
    }
    return CustomerHomePage(
      userId: Supabase.instance.client.auth.currentUser!.id,
    );
  }
}

class RoleUnavailablePage extends StatelessWidget {
  const RoleUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) => const Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Center(
        child: Text('تعذر تحديد صلاحيات الحساب. حاول تسجيل الدخول مجددًا.'),
      ),
    ),
  );
}

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validation = passwordResetValidation(_email.text);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await AuthRepository(Supabase.instance.client).resetPassword(
        _email.text,
        redirectTo: kIsWeb
            ? Uri.base.origin
            : 'ly.sanad.sanad://login-callback/',
      );
      if (mounted) {
        setState(
          () => _message = 'تم إرسال رابط استعادة كلمة المرور إلى بريدك.',
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('أدخل بريدك الإلكتروني وسنرسل لك رابطًا آمنًا.'),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('إرسال الرابط'),
          ),
        ],
      ),
    ),
  );
}

class AuthenticatedPlaceholder extends StatelessWidget {
  const AuthenticatedPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('تم تسجيل الدخول إلى سند')));
  }
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: selected ? const Color(0xFFE8F6EE) : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: selected ? const Color(0xFF164C3B) : const Color(0xFFE4ECE6),
        width: selected ? 1.5 : 1,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFDFF3EA),
              child: Icon(icon, color: const Color(0xFF164C3B)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(height: 1.35)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.arrow_back_ios_new,
              size: selected ? 24 : 16,
              color: const Color(0xFF164C3B),
            ),
          ],
        ),
      ),
    ),
  );
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
  AppRole _selectedRole = AppRole.customer;
  bool _roleChosen = false;
  bool _signUp = true;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _resendingConfirmation = false;
  String? _error;
  String? _message;

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
      _message = null;
    });
    try {
      final auth = AuthRepository(Supabase.instance.client);
      if (_signUp) {
        await auth.signUp(
          form: form,
          fullName: _name.text,
          phone: _phone.text,
          role: _selectedRole,
          emailRedirectTo: kIsWeb
              ? Uri.base.origin
              : 'ly.sanad.sanad://login-callback/',
        );
      } else {
        await auth.signIn(form);
      }
      if (_signUp && mounted) {
        final message = authSuccessMessage(
          isSignUp: true,
          hasSession: Supabase.instance.client.auth.currentSession != null,
        );
        if (message != null) {
          setState(() => _message = message);
        }
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'تعذر الاتصال بخدمة الحساب. تحقق من الإنترنت وحاول مرة أخرى.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendConfirmation() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'أدخل بريدك الإلكتروني أولًا.');
      return;
    }
    setState(() {
      _resendingConfirmation = true;
      _error = null;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: kIsWeb
            ? Uri.base.origin
            : 'ly.sanad.sanad://login-callback/',
      );
      if (mounted) {
        setState(
          () => _message =
              'أُعيد إرسال رابط التفعيل. افحص Spam وانتظر قليلًا قبل إعادة المحاولة.',
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _resendingConfirmation = false);
    }
  }

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }
    if (message.contains('email not confirmed')) {
      return 'أكد بريدك الإلكتروني أولًا، ثم حاول تسجيل الدخول.';
    }
    if (message.contains('user already registered')) {
      return 'هذا البريد مسجل من قبل. جرّب تسجيل الدخول بدل إنشاء حساب جديد.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'تم تجاوز عدد المحاولات مؤقتًا. انتظر قليلًا ثم أعد المحاولة.';
    }
    return 'تعذر إكمال العملية: ${error.message}';
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
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF164C3B), Color(0xFF2C7356)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22164C3B),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'س',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سند',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'خدمة موثوقة تبدأ من بيتك',
                            style: TextStyle(
                              color: Color(0xFFDFF3EA),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.home_repair_service_outlined,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _signUp ? 'أنشئ حسابك في سند' : 'مرحبًا بك في سند',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _signUp
                    ? 'خطوة واحدة لتصل إلى محترفين موثوقين في طرابلس.'
                    : 'سندك في كل خدمة منزلية، بوضوح وراحة.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF4D6B5A),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              if (_signUp && !_roleChosen) ...[
                const Text(
                  'كيف ستستخدم سند؟',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text('اختر دورك لنجهّز لك التجربة المناسبة.'),
                const SizedBox(height: 18),
                _RoleChoiceCard(
                  icon: Icons.home_outlined,
                  title: 'أبحث عن خدمة منزلية',
                  subtitle: 'أنا عميل وأريد طلب خدمة لمنزلي.',
                  selected: _selectedRole == AppRole.customer,
                  onTap: () => setState(() {
                    _selectedRole = AppRole.customer;
                    _roleChosen = true;
                  }),
                ),
                const SizedBox(height: 12),
                _RoleChoiceCard(
                  icon: Icons.handyman_outlined,
                  title: 'أقدّم خدمات منزلية',
                  subtitle: 'أنا عامل وأريد استقبال الطلبات وتقديم العروض.',
                  selected: _selectedRole == AppRole.worker,
                  onTap: () => setState(() {
                    _selectedRole = AppRole.worker;
                    _roleChosen = true;
                  }),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() => _signUp = false),
                  child: const Text('لديك حساب؟ تسجيل الدخول'),
                ),
              ] else ...[
                if (_signUp) ...[
                  Row(
                    children: [
                      Icon(
                        _selectedRole == AppRole.worker
                            ? Icons.handyman_outlined
                            : Icons.home_outlined,
                        color: const Color(0xFF164C3B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedRole == AppRole.worker
                            ? 'إنشاء حساب مقدم خدمة'
                            : 'إنشاء حساب عميل',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _roleChosen = false),
                        child: const Text('تغيير'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
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
                obscureText: _obscurePassword,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'إظهار كلمة المرور'
                        : 'إخفاء كلمة المرور',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (_signUp &&
                    Supabase.instance.client.auth.currentSession == null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: (_loading || _resendingConfirmation)
                          ? null
                          : _resendConfirmation,
                      icon: _resendingConfirmation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mark_email_read_outlined),
                      label: const Text('إعادة إرسال رابط التفعيل'),
                    ),
                  ),
              ],
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
                    : () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PasswordResetPage(),
                        ),
                      ),
                child: const Text('نسيت كلمة المرور؟'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _signUp = !_signUp;
                        _roleChosen = _signUp ? false : _roleChosen;
                        _error = null;
                        _message = null;
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

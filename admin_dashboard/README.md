# Sanad Admin Web

لوحة إدارة مستقلة فعليًا عن تطبيق الهاتف والعامل. لها مشروع Flutter Web منفصل داخل `admin_dashboard/`، ومدخل تشغيل مستقل هو `admin_dashboard/lib/main.dart`.

## التحقق من الدور

البوابة لا تعرض لوحة الإدارة إلا بعد:

1. وجود جلسة Supabase.
2. قراءة الدور النشط من `user_roles`.
3. اجتياز `AdminRouteGuard` بدور `admin` أو `operator` بعد أن يحوله resolver إلى `AppRole.admin`.

أي مستخدم غير مصرح يرى صفحة منع، ولا يحصل على `OperatorPage`.

## التشغيل والبناء

```bash
cd admin_dashboard
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
```

الناتج:

```text
admin_dashboard/build/web
```

## النشر

يجب نشر الناتج في hostname مستقل، مثل:

```text
admin.sanad.ly
```

ولا يُنصح بوضعه تحت مسار تطبيق العميل نفسه. حاليًا لا يوجد Domain أو HTTPS على VPS، لذلك لم يتم نشر هذا الـ entrypoint المستقل على الإنترنت بعد.

## الحالة الأمنية

هذا حارس Frontend فقط. لا يعتبر Backend security مكتملًا قبل تطبيق Migration 013 واختبار Customer/Worker/Admin وStorage وRPCs وRLS بجلسات حقيقية.

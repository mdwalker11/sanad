# Sanad

سند — منصة الخدمات المنزلية في طرابلس.

## الوضع الحالي

هذا المستودع يحتوي على بداية تطبيق Flutter الموحد Android/iOS/Web، ووثائق المنتج، ومخطط PostgreSQL أولي.

## التطوير المحلي

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

## المسارات المهمة

- `lib/` تطبيق Flutter.
- `test/` الاختبارات.
- `backend/schema.sql` مخطط قاعدة البيانات الأولي.
- `docs/` وثائق المنتج والتشغيل.
- `.github/workflows/ci.yml` فحص آلي عند كل Push وPull Request.

## ملاحظات الأمان

لا تضع كلمات المرور أو مفاتيح الإدارة أو ملفات التوقيع داخل المستودع. استخدم GitHub Actions Secrets وبيئات النشر الآمنة.

# Admin Web — النشر الآمن والحالة الحالية

## الحالة

تم فصل لوحة الإدارة إلى entrypoint مستقل داخل `admin_dashboard/`. لا يوجد رابط إدارة داخل تطبيق الهاتف، ولا يتم تضمين `OperatorPage` في `lib/main.dart`.

## تشغيل Admin Web

يحتاج إلى إعدادات build فقط، ولا يحتاج مفاتيح سرية:

```bash
cd admin_dashboard
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
```

تسجيل الدخول يتم داخل البوابة المستقلة، وبعده تقرأ البوابة `user_roles` وتمنع أي دور غير `admin/operator` من عرض اللوحة.

## النشر على VPS

لم يتم نشر Admin Web على عنوان IP/HTTP؛ لا يوجد حاليًا Domain أو HTTPS، ولا ينبغي إرسال بيانات المشرف عبر HTTP.

عند توفر Domain:

```text
admin.sanad.ly → A → 187.127.72.228
```

سيتم:

1. إعداد Nginx باسم النطاق.
2. إصدار شهادة TLS.
3. فرض تحويل HTTP إلى HTTPS.
4. رفع الأرشيف إلى مسار مرحلي.
5. مطابقة SHA-256 محليًا وعن بعد.
6. إنشاء backup timestamped.
7. تشغيل nginx -t.
8. التبديل الذري وإعادة تحميل Nginx.
9. التحقق من HTTPS خارجيًا.

لا ترسل كلمات مرور أو OTP أو مفاتيح خاصة؛ المطلوب فقط اسم النطاق وتعديل DNS إذا كان الحساب عندك.

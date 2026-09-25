# Sanad — Development Status

آخر تحديث: بعد commit `8c2e2ce`

## البيئة الفعلية (مقاسة، لا مفترضة)

| المكوّن | الحالة |
|---|---|
| Flutter | 3.35.5 stable / Dart 3.9.2 — `/data/flutter` |
| Android SDK | 34 + build-tools 34.0.0 — `/data/android` |
| JDK | 17 |
| Gradle | 8.7 (استخدم `--no-daemon` دائماً) |
| Supabase | مشروع `vpryzkqoxygrqxrluvpj` — PostgreSQL 17.6، eu-west-1 |
| الذاكرة | 4 GB cgroup — daemon متروك يلتهم ثلثها |
| iOS | غير متاح (لا macOS/Xcode على هذا المضيف) |

## التحقق الحالي

```text
$ flutter analyze
No issues found! (ran in 2.6s)

$ flutter test
00:41 +102: All tests passed!

$ flutter build apk --debug
✓ Built build/app/outputs/flutter-apk/app-debug.apk

$ aapt dump badging app-debug.apk
package: name='ly.sanad.sanad' versionCode='1' versionName='0.1.0'
targetSdkVersion:'36'
```

## قاعدة البيانات — مطبَّقة ومتحقَّق منها

| العنصر | العدد |
|---|---|
| الجداول | 19/19 |
| الدوال | 14/14 |
| Triggers | 14 |
| RLS | مفعّل على 19/19 جدول، 35 سياسة |

تفاصيل الفجوتين المكتشفتين والمصلحتين في `backend/MIGRATIONS_APPLIED.md`:
- `handle_new_user()` كانت تتجاهل `requested_role` → كل مستخدم يظهر كعميل
- `accept_service_offer()` كانت مفقودة تماماً → قبول العروض معطّل

## المنجز

### العميل
- كتالوج الخدمات الخمس من Supabase
- إنشاء طلب (فوري/مجدول) مع تحقق من المدخلات
- متابعة الطلبات وحالاتها بالعربية
- بطاقة الثقة تشرح معايير اختيار المحترفين (`_TrustSheet`)

### العامل
- استعراض الطلبات وتقديم العروض
- ملف العامل المهني
- **سجل الأعمال والأرباح** — محصَّل/مستحق/عمولة/متوسط، بأربع حالات كاملة
- **دعم سند** — قنوات تواصل + أسئلة متكررة، يعمل دون اتصال

### الإشعارات
- عدّاد غير المقروء في العنوان، وتمييز بصري للجديد
- "تعليم الكل كمقروء" دفعة واحدة
- توقيت عربي نسبي صحيح المثنى والجمع ("قبل ساعتين"، "قبل 5 دقائق")

### الحساب
- تسجيل دخول/إنشاء حساب مع إسناد الدور الصحيح
- إدارة الحساب بعناصر تفاعلية مختبَرة بالضغط

## معمارية الاختبار

الشاشات الجديدة تعتمد على واجهات مجردة لا على `SupabaseClient`:

- `WorkerEarningsSource` ← `worker_earnings_page.dart`
- `WorkerProfileSink` ← `worker_profile_page.dart`

هذا يسمح باختبار حالات التحميل والفشل والفراغ دون شبكة.

## مزالق موثّقة

1. **سطح الاختبار الافتراضي 800×600** — عناصر `ListView` تحت الطية غائبة عن
   الشجرة تماماً. كبّر `tester.view.physicalSize` قبل `pumpWidget`.
2. **`super.key` يستقر على الـ widget الخارجي** لا على `ListTile` الذي يبنيه.
3. **اختبار الظهور لا يكشف زراً ميتاً** — `onTap: () {}` يمر من كل اختبار
   يسأل `findsOneWidget`. لا بد من `tester.tap()` وفحص `onTap != null`.
4. **migration مكتوب ≠ migration مطبَّق** — تحقّق من `pg_proc`/`pg_tables`.
5. **`kotlin {}` بلا إضافة Kotlin مطبّقة** — كان `android/app/build.gradle.kts`
   يضبط `jvmTarget` دون `id("org.jetbrains.kotlin.android")` في `plugins`،
   فكان البناء يفشل كلياً رغم أن الاختبارات كلها خضراء.
6. **NDK**: إضافات `app_links`/`shared_preferences_android`/`url_launcher_android`
   تتطلب `28.2.13676358`؛ ثبّته صراحةً بدل `flutter.ndkVersion`.

## غير محقَّق منه بصراحة

- **لا اختبار على جهاز Android حقيقي** — لا محاكي ولا هاتف متصل. التحقق
  اقتصر على `flutter test` و`flutter build`.
- **لا اختبار end-to-end للتسجيل من الواجهة** — إصلاح الدور تُحقق منه
  بإدراج مباشر في `auth.users`، وهو يثبت الـ trigger لا رحلة الواجهة.
- APK متصل بالإنتاج يحتاج `SUPABASE_URL` و`SUPABASE_PUBLISHABLE_KEY`
  وقت البناء عبر `--dart-define`.

## الأولويات التالية

1. تغطية `auth_page.dart` باختبارات ضغط — 13 عنصر تفاعل بلا `Key`
3. إكمال اختيار التاريخ/العنوان/الصور في إنشاء الطلب
4. بناء APK متصل والتحقق منه على جهاز حقيقي

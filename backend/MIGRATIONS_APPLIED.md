# حالة تطبيق Migrations على Supabase

المشروع: `vpryzkqoxygrqxrluvpj` (eu-west-1، PostgreSQL 17.6)
طريقة التطبيق: Supabase Management API (`/v1/projects/{ref}/database/query`)

## تم التحقق منه بالاستعلام المباشر

| العنصر | متوقع | موجود |
|---|---|---|
| الدوال | 14 | 14 ✓ |
| الجداول | 19 | 19 ✓ |
| Triggers | 6 | 14 ✓ |
| RLS | كل الجداول | 19/19 ✓ |
| سياسات RLS | — | 35 |

## فجوتان اكتُشفتا وأُصلحتا

### 1. `014_signup_role_assignment.sql` — لم يكن مطبَّقاً
`handle_new_user()` كانت تُدرج في `profiles` فقط ولا تذكر `requested_role`
إطلاقاً ولا تُدرج أي صف في `user_roles`. النتيجة: كل مستخدم يظهر كعميل.

أُصلح وتُحقّق منه بأربع حالات حية:

| `requested_role` المرسل | الدور الممنوح |
|---|---|
| `worker` | `worker` ✓ |
| `customer` | `customer` ✓ |
| `admin` (محاولة انتحال) | `customer` ✓ مرفوضة |
| غير مرسل | `customer` ✓ |

**Backfill:** 8 مستخدمين كانوا بلا أي دور. عولجوا بأثر رجعي من
`raw_user_meta_data->>'requested_role'`. النتيجة: 7 عملاء، 1 عامل، 1 مشرف.
لا مستخدم بلا دور.

### 2. `accept_service_offer()` — دالة مفقودة
`lib/offers/offer_repository.dart:40` يستدعيها، لكنها لم تكن موجودة في
قاعدة البيانات — أي أن قبول العروض كان معطّلاً بالكامل. طُبِّق
`003_accept_offer_rpc.sql` و`004_worker_dispatch_rls.sql`.

## الدرس

ملف migration مكتوب في المستودع **لا يعني** أنه مطبَّق على قاعدة البيانات.
تحقّق دائماً بالاستعلام عن الكائن نفسه في `pg_proc` / `pg_tables` /
`pg_trigger` قبل افتراض أن الإصلاح فعّال.

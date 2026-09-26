-- 015: العمولة قابلة للضبط من الخادم بدل رقم مكرر في الشيفرة.
--
-- ⚠️ تصحيح لتشخيص خاطئ سُجّل أثناء العمل:
-- ظننت أولاً أن `commission_rate` ثغرة أمنية، لأن الفحص أظهر:
--
--   insert_policies_guarding_commission = 0
--   check_constraints_on_commission     = 0
--
-- كان الاستنتاج خاطئاً. الحماية كانت موجودة في طبقة ثالثة لم أفحصها:
-- الدالة `guard_service_offer_insert()` تتجاوز ما يرسله العميل صراحةً:
--
--   new.status := 'pending'; new.commission_rate := 20.00;
--
-- وأثبت اختبار حي أن الحراس يعملون: محاولة إدراج عرض بعامل غير معتمد
-- رُدّت بـ `worker_not_approved`، ومحاولة ترقية `verification_status`
-- ذاتياً رُدّت بحارس `guard_worker_profile_fields`.
--
-- الدرس: غياب نوع واحد من الحماية (RLS/CHECK) لا يعني غياب الحماية.
-- افحص الطبقات الثلاث — السياسات، والقيود، ودوال الـ trigger — قبل الحكم.
--
-- لماذا يبقى هذا الملف مفيداً إذن:
--   1. كان الرقم 20.00 مكرراً في ثلاثة مواضع (Dart، الحارس، افتراضي العمود).
--      تغيير العمولة كان يتطلب إعادة نشر التطبيق. صار الآن صفاً واحداً.
--   2. لا قيد كان يمنع عرضاً إجماليه 100 بينما تفاصيله 500.
--   3. طبقة دفاع إضافية لو عُطّل الحارس القائم يوماً.

begin;

-- 1) جدول إعدادات العمولة — قابل للتغيير دون إعادة نشر التطبيق.
create table if not exists platform_settings (
  key         text primary key,
  numeric_value numeric,
  text_value  text,
  updated_at  timestamptz not null default now()
);

insert into platform_settings(key, numeric_value)
values ('default_commission_rate', 20.00)
on conflict (key) do nothing;

alter table platform_settings enable row level security;

-- الجميع يقرأ (العامل يحتاج معرفة العمولة لعرض صافي ربحه)، ولا أحد يكتب
-- إلا عبر service_role.
drop policy if exists "anyone can read platform settings" on platform_settings;
create policy "anyone can read platform settings"
  on platform_settings for select
  using (true);

-- 2) دالة تُرجع العمولة السارية.
create or replace function current_commission_rate()
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select numeric_value from platform_settings where key = 'default_commission_rate'),
    20.00
  );
$$;

-- 3) trigger يفرض العمولة عند الإدراج ويمنع تعديلها لاحقاً.
create or replace function enforce_offer_commission()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    -- تُفرض دائماً من الخادم مهما أرسل العميل.
    new.commission_rate := current_commission_rate();

  elsif tg_op = 'UPDATE' then
    -- لا يجوز تغيير عمولة عرض قائم.
    if new.commission_rate is distinct from old.commission_rate then
      new.commission_rate := old.commission_rate;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_offer_commission on service_offers;
create trigger trg_enforce_offer_commission
  before insert or update on service_offers
  for each row execute function enforce_offer_commission();

-- 4) حزام أمان ثانٍ: قيد يرفض أي قيمة خارج النطاق المعقول حتى لو
--    عُطّل الـ trigger يوماً.
alter table service_offers
  drop constraint if exists service_offers_commission_rate_range;
alter table service_offers
  add constraint service_offers_commission_rate_range
  check (commission_rate >= 0 and commission_rate <= 100);

-- 5) اتساق المبالغ: المجموع يجب أن يساوي مكوّناته عندما تُذكر.
--    يمنع عرضاً يقول "الإجمالي 100" بينما تفاصيله 500.
alter table service_offers
  drop constraint if exists service_offers_amounts_consistent;
alter table service_offers
  add constraint service_offers_amounts_consistent
  check (
    (visit_amount + labor_amount + materials_amount) = 0
    or abs(total_amount - (visit_amount + labor_amount + materials_amount)) < 0.01
  );

commit;

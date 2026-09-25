-- Sanad live release: security hardening 011 + 012
-- Run as ONE query in Supabase SQL Editor after migrations 001-010.
-- Project: vpryzkqoxygrqxrluvpj
-- Expected result: Success. No rows returned.

-- 011_security_hardening.sql
create or replace function public.sanad_is_operator()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.user_roles
    where user_id = auth.uid() and role in ('admin','operator') and is_active);
$$;
grant execute on function public.sanad_is_operator() to authenticated;
revoke execute on function public.sanad_is_operator() from public;

create or replace function public.guard_worker_profile_fields()
returns trigger language plpgsql security invoker set search_path = public
as $$
begin
  if not public.sanad_is_operator() then
    if tg_op = 'INSERT' then
      if new.user_id <> auth.uid() then raise exception 'worker_profile_owner_mismatch'; end if;
      new.verification_status := 'pending'; new.commission_rate := 20.00;
      new.rating := 0; new.completed_orders := 0;
    elsif tg_op = 'UPDATE' then
      if old.user_id <> auth.uid() or new.user_id <> old.user_id then
        raise exception 'worker_profile_owner_mismatch';
      end if;
      if new.verification_status is distinct from old.verification_status
         or new.commission_rate is distinct from old.commission_rate
         or new.rating is distinct from old.rating
         or new.completed_orders is distinct from old.completed_orders then
        raise exception 'worker_profile_protected_field';
      end if;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists guard_worker_profile_fields on public.worker_profiles;
create trigger guard_worker_profile_fields before insert or update on public.worker_profiles
for each row execute function public.guard_worker_profile_fields();

create or replace function public.guard_customer_order_insert()
returns trigger language plpgsql security invoker set search_path = public
as $$
begin
  if not public.sanad_is_operator() then
    if new.customer_id <> auth.uid() then raise exception 'order_owner_mismatch'; end if;
    new.status := 'awaiting_offers'; new.selected_worker_id := null;
    new.selected_offer_id := null; new.customer_total := null;
    if new.address_id is not null and not exists
      (select 1 from public.customer_addresses a where a.id = new.address_id and a.customer_id = auth.uid()) then
      raise exception 'address_not_owned';
    end if;
  end if;
  if new.booking_type in ('scheduled','time_window') and
     (new.preferred_start is null or new.preferred_end is null or new.preferred_end <= new.preferred_start) then
    raise exception 'invalid_booking_window';
  end if;
  return new;
end;
$$;
drop trigger if exists guard_customer_order_insert on public.service_orders;
create trigger guard_customer_order_insert before insert on public.service_orders
for each row execute function public.guard_customer_order_insert();

create or replace function public.guard_service_offer_insert()
returns trigger language plpgsql security invoker set search_path = public
as $$
begin
  if not public.sanad_is_operator() then
    if new.worker_id <> auth.uid() then raise exception 'offer_owner_mismatch'; end if;
    if not exists (select 1 from public.worker_profiles where user_id = auth.uid() and verification_status = 'approved') then
      raise exception 'worker_not_approved';
    end if;
    if not exists (select 1 from public.service_orders where id = new.order_id and status = 'awaiting_offers') then
      raise exception 'order_not_accepting_offers';
    end if;
    new.status := 'pending'; new.commission_rate := 20.00;
  end if;
  if new.total_amount < 0 or new.visit_amount < 0 or new.labor_amount < 0 or
     new.materials_amount < 0 or new.commission_rate < 0 or new.commission_rate > 100 then
    raise exception 'invalid_offer_amounts';
  end if;
  return new;
end;
$$;
drop trigger if exists guard_service_offer_insert on public.service_offers;
create trigger guard_service_offer_insert before insert on public.service_offers
for each row execute function public.guard_service_offer_insert();

drop policy if exists "customers can update own orders" on public.service_orders;
create index if not exists service_orders_selected_worker_idx on public.service_orders(selected_worker_id);
create index if not exists service_orders_address_idx on public.service_orders(address_id);
create index if not exists order_media_order_idx on public.order_media(order_id);
create index if not exists complaints_order_idx on public.complaints(order_id);
create index if not exists reviews_worker_idx on public.reviews(worker_id);
create index if not exists reviews_customer_idx on public.reviews(customer_id);
create index if not exists order_events_order_idx on public.order_events(order_id, created_at desc);

drop policy if exists "sanad media participants read" on storage.objects;
create policy "sanad media participants read" on storage.objects for select to authenticated
using (bucket_id = 'sanad-media' and (storage.foldername(name))[1] = auth.uid()::text
  and (storage.foldername(name))[2] ~ '^[0-9a-fA-F-]{36}$'
  and exists (select 1 from public.service_orders o where o.id = ((storage.foldername(name))[2])::uuid
    and (o.customer_id = auth.uid() or o.selected_worker_id = auth.uid())));

drop policy if exists "sanad media users upload" on storage.objects;
create policy "sanad media users upload" on storage.objects for insert to authenticated
with check (bucket_id = 'sanad-media' and (storage.foldername(name))[1] = auth.uid()::text
  and (storage.foldername(name))[2] ~ '^[0-9a-fA-F-]{36}$'
  and exists (select 1 from public.service_orders o where o.id = ((storage.foldername(name))[2])::uuid
    and (o.customer_id = auth.uid() or o.selected_worker_id = auth.uid())));

-- 012_mutation_permissions.sql
drop policy if exists "operators update worker verification" on public.worker_profiles;
drop policy if exists "operators update complaints" on public.complaints;
revoke update on public.complaints from authenticated;
revoke update on public.settlements from authenticated;

drop policy if exists "workers can update own pending offers" on public.service_offers;
create policy "workers can update own pending offers" on public.service_offers for update to authenticated
using (worker_id = auth.uid() and status = 'pending')
with check (worker_id = auth.uid() and status = 'pending' and commission_rate between 0 and 100
  and total_amount >= 0 and visit_amount >= 0 and labor_amount >= 0 and materials_amount >= 0);

revoke delete on public.service_orders from authenticated;
revoke delete on public.service_offers from authenticated;
revoke delete on public.order_events from authenticated;
revoke delete on public.settlements from authenticated;
revoke delete on public.reviews from authenticated;
revoke delete on public.complaints from authenticated;

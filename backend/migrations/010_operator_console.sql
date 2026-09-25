-- Sanad operator console access and moderation actions
-- Apply after 009_operations_notifications_settlements.sql.

create or replace function public.is_operator()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_roles ur
    where ur.user_id = auth.uid()
      and ur.role in ('admin', 'operator')
      and ur.is_active
  );
$$;

revoke execute on function public.is_operator() from public;
grant execute on function public.is_operator() to authenticated;

-- Operators need read-only operational visibility.
drop policy if exists "operators read worker profiles" on public.worker_profiles;
create policy "operators read worker profiles"
on public.worker_profiles for select
to authenticated using (public.is_operator());

drop policy if exists "operators update worker verification" on public.worker_profiles;
create policy "operators update worker verification"
on public.worker_profiles for update
to authenticated
using (public.is_operator())
with check (public.is_operator());

drop policy if exists "operators read all complaints" on public.complaints;
create policy "operators read all complaints"
on public.complaints for select
to authenticated using (public.is_operator());

drop policy if exists "operators update complaints" on public.complaints;
create policy "operators update complaints"
on public.complaints for update
to authenticated
using (public.is_operator())
with check (public.is_operator());

drop policy if exists "operators read all orders" on public.service_orders;
create policy "operators read all orders"
on public.service_orders for select
to authenticated using (public.is_operator());

-- Explicit moderation RPCs keep verification and complaint resolution auditable.
create or replace function public.operator_set_worker_verification(
  p_worker_id uuid,
  p_status public.worker_verification_status
)
returns public.worker_profiles
language plpgsql
security definer
set search_path = public
as $$
declare v_profile public.worker_profiles;
begin
  if not public.is_operator() then raise exception 'operator_required'; end if;
  update public.worker_profiles
  set verification_status = p_status, updated_at = now()
  where user_id = p_worker_id
  returning * into v_profile;
  if v_profile.user_id is null then raise exception 'worker_not_found'; end if;
  insert into public.notifications(recipient_id, type, title_ar, body_ar, payload)
  values (p_worker_id, 'worker_verification', 'تحديث اعتماد العامل',
    'تم تحديث حالة ملفك إلى: ' || p_status::text,
    jsonb_build_object('worker_id', p_worker_id, 'status', p_status));
  return v_profile;
end;
$$;

create or replace function public.operator_resolve_complaint(
  p_complaint_id uuid,
  p_status text,
  p_resolution text
)
returns public.complaints
language plpgsql
security definer
set search_path = public
as $$
declare v_complaint public.complaints;
begin
  if not public.is_operator() then raise exception 'operator_required'; end if;
  if p_status not in ('resolved', 'rejected', 'investigating') then
    raise exception 'invalid_complaint_status';
  end if;
  update public.complaints
  set status = p_status, resolution = nullif(trim(p_resolution), ''),
      resolved_by = case when p_status in ('resolved','rejected') then auth.uid() else null end,
      resolved_at = case when p_status in ('resolved','rejected') then now() else null end
  where id = p_complaint_id
  returning * into v_complaint;
  if v_complaint.id is null then raise exception 'complaint_not_found'; end if;
  return v_complaint;
end;
$$;

revoke execute on function public.operator_set_worker_verification(uuid, public.worker_verification_status) from public;
revoke execute on function public.operator_resolve_complaint(uuid, text, text) from public;
grant execute on function public.operator_set_worker_verification(uuid, public.worker_verification_status) to authenticated;
grant execute on function public.operator_resolve_complaint(uuid, text, text) to authenticated;

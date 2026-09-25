-- Sanad production order-transition migration
-- Clean SQL: no readout line prefixes.

-- Sanad secure order transitions
-- Apply after 004_worker_dispatch_rls.sql.
-- Prevents customers from mutating lifecycle/status fields directly.

drop policy if exists "customers can update own orders" on public.service_orders;

create or replace function public.worker_update_order_status(
  p_order_id uuid,
  p_to_status public.order_status
)
returns public.service_orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.service_orders;
  v_from_status public.order_status;
begin
  select * into v_order
  from public.service_orders
  where id = p_order_id
    and selected_worker_id = auth.uid()
  for update;

  if v_order.id is null then
    raise exception 'order_not_found_or_not_assigned';
  end if;
  v_from_status := v_order.status;

  if not (
    (v_order.status = 'confirmed' and p_to_status = 'on_the_way') or
    (v_order.status = 'on_the_way' and p_to_status = 'in_progress') or
    (v_order.status = 'in_progress' and p_to_status = 'awaiting_completion')
  ) then
    raise exception 'invalid_worker_status_transition';
  end if;

  update public.service_orders
  set status = p_to_status, updated_at = now()
  where id = p_order_id
  returning * into v_order;

  insert into public.order_events(order_id, actor_id, from_status, to_status)
  values (p_order_id, auth.uid(), v_from_status, p_to_status);

  return v_order;
end;
$$;

create or replace function public.customer_complete_order(p_order_id uuid)
returns public.service_orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.service_orders;
  v_from_status public.order_status;
begin
  select * into v_order
  from public.service_orders
  where id = p_order_id
    and customer_id = auth.uid()
  for update;

  if v_order.id is null then
    raise exception 'order_not_found_or_not_owned';
  end if;
  v_from_status := v_order.status;
  if v_order.status <> 'awaiting_completion' then
    raise exception 'order_not_waiting_for_completion';
  end if;

  update public.service_orders
  set status = 'completed', completed_at = now(), updated_at = now()
  where id = p_order_id
  returning * into v_order;

  insert into public.order_events(order_id, actor_id, from_status, to_status, note)
  values (p_order_id, auth.uid(), v_from_status, 'completed', 'أكد العميل إنجاز الخدمة');

  return v_order;
end;
$$;

create or replace function public.customer_cancel_order(p_order_id uuid)
returns public.service_orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.service_orders;
  v_from_status public.order_status;
begin
  select * into v_order
  from public.service_orders
  where id = p_order_id
    and customer_id = auth.uid()
  for update;

  if v_order.id is null then
    raise exception 'order_not_found_or_not_owned';
  end if;
  v_from_status := v_order.status;
  if v_order.status not in ('new', 'under_review', 'awaiting_offers') then
    raise exception 'order_cannot_be_cancelled_now';
  end if;

  update public.service_orders
  set status = 'cancelled', updated_at = now()
  where id = p_order_id
  returning * into v_order;

  insert into public.order_events(order_id, actor_id, from_status, to_status, note)
  values (p_order_id, auth.uid(), v_from_status, 'cancelled', 'ألغى العميل الطلب');

  return v_order;
end;
$$;

create policy "approved workers can read assigned orders"
on public.service_orders for select
to authenticated
using (
  selected_worker_id = auth.uid()
  and exists (
    select 1
    from public.worker_profiles wp
    where wp.user_id = auth.uid()
      and wp.verification_status = 'approved'
  )
);


revoke execute on function public.worker_update_order_status(uuid, public.order_status) from public;
revoke execute on function public.customer_complete_order(uuid) from public;
revoke execute on function public.customer_cancel_order(uuid) from public;
grant execute on function public.worker_update_order_status(uuid, public.order_status) to authenticated;
grant execute on function public.customer_complete_order(uuid) to authenticated;
grant execute on function public.customer_cancel_order(uuid) to authenticated;

-- Sanad worker status controls
-- Apply after 005_secure_order_transitions.sql.

create or replace function public.worker_update_order_status(
  p_order_id uuid,
  p_to_status public.order_status
)
returns public.service_orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.service_orders;
  v_from_status public.order_status;
begin
  select * into v_order
  from public.service_orders
  where id = p_order_id
    and selected_worker_id = auth.uid()
  for update;

  if v_order.id is null then
    raise exception 'order_not_found_or_not_assigned';
  end if;
  v_from_status := v_order.status;

  if not (
    (v_from_status = 'confirmed' and p_to_status = 'on_the_way') or
    (v_from_status = 'on_the_way' and p_to_status = 'in_progress') or
    (v_from_status = 'in_progress' and p_to_status = 'awaiting_completion')
  ) then
    raise exception 'invalid_worker_status_transition';
  end if;

  update public.service_orders
  set status = p_to_status, updated_at = now()
  where id = p_order_id
  returning * into v_order;

  insert into public.order_events(order_id, actor_id, from_status, to_status)
  values (p_order_id, auth.uid(), v_from_status, p_to_status);

  return v_order;
end;
$$;

drop policy if exists "approved workers can read assigned orders" on public.service_orders;

create policy "approved workers can read assigned orders"
on public.service_orders for select
to authenticated
using (
  selected_worker_id = auth.uid()
  and exists (
    select 1 from public.worker_profiles wp
    where wp.user_id = auth.uid()
      and wp.verification_status = 'approved'
  )
);

revoke execute on function public.worker_update_order_status(uuid, public.order_status) from public;
grant execute on function public.worker_update_order_status(uuid, public.order_status) to authenticated;

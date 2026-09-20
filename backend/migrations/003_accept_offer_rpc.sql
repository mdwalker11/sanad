-- Sanad offer acceptance RPC
-- Run once in Supabase SQL Editor after 002_auth_profile_trigger.sql.

create or replace function public.accept_service_offer(
  p_order_id uuid,
  p_offer_id uuid
)
returns public.service_orders
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_order public.service_orders;
  v_offer public.service_offers;
begin
  select * into v_order
  from public.service_orders
  where id = p_order_id
    and customer_id = auth.uid()
  for update;

  if v_order.id is null then
    raise exception 'order_not_found_or_not_owned';
  end if;

  select * into v_offer
  from public.service_offers
  where id = p_offer_id
    and order_id = p_order_id
    and status = 'pending';

  if v_offer.id is null then
    raise exception 'offer_not_found_or_unavailable';
  end if;

  if v_order.status not in ('awaiting_offers', 'offer_selected') then
    raise exception 'order_not_accepting_offers';
  end if;

  update public.service_offers
  set status = case when id = p_offer_id then 'accepted' else 'rejected' end
  where order_id = p_order_id
    and status = 'pending';

  update public.service_orders
  set selected_offer_id = p_offer_id,
      selected_worker_id = v_offer.worker_id,
      customer_total = v_offer.total_amount,
      status = 'confirmed',
      updated_at = now()
  where id = p_order_id
  returning * into v_order;

  insert into public.order_events(order_id, actor_id, from_status, to_status, note)
  values (p_order_id, auth.uid(), v_order.status, 'confirmed', 'تم قبول عرض العامل');

  return v_order;
end;
$$;

grant execute on function public.accept_service_offer(uuid, uuid) to authenticated;

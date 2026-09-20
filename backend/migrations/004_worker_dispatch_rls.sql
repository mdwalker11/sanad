-- Sanad worker dispatch RLS policies
-- Run once after 003_accept_offer_rpc.sql.

create policy "approved workers can read awaiting orders"
on public.service_orders for select
to authenticated
using (
  status = 'awaiting_offers'
  and exists (
    select 1
    from public.worker_profiles wp
    where wp.user_id = auth.uid()
      and wp.verification_status = 'approved'
  )
);

create policy "workers can read own offers"
on public.service_offers for select
to authenticated
using (worker_id = auth.uid());

create policy "approved workers can submit offers"
on public.service_offers for insert
to authenticated
with check (
  worker_id = auth.uid()
  and exists (
    select 1
    from public.worker_profiles wp
    where wp.user_id = auth.uid()
      and wp.verification_status = 'approved'
  )
);

revoke execute on function public.accept_service_offer(uuid, uuid) from public;
grant execute on function public.accept_service_offer(uuid, uuid) to authenticated;

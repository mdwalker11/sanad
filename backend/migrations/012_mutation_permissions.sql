-- Sanad security hardening follow-up 012
-- Apply after 011_security_hardening.sql.
-- Removes broad client-side mutation paths; moderation goes through RPCs.

-- Operator moderation must use the audited RPCs, not arbitrary row updates.
drop policy if exists "operators update worker verification" on public.worker_profiles;
drop policy if exists "operators update complaints" on public.complaints;
revoke update on public.complaints from authenticated;
revoke update on public.settlements from authenticated;

-- Keep worker self-service edits, while 011's trigger protects moderation fields.
-- Keep customer profile/address updates governed by their existing owner policies.

-- Worker offers may only be edited while pending and by their owner.
drop policy if exists "workers can update own pending offers" on public.service_offers;
create policy "workers can update own pending offers"
on public.service_offers for update
to authenticated
using (worker_id = auth.uid() and status = 'pending')
with check (
  worker_id = auth.uid()
  and status = 'pending'
  and commission_rate between 0 and 100
  and total_amount >= 0
  and visit_amount >= 0
  and labor_amount >= 0
  and materials_amount >= 0
);

-- Do not allow deletion of financial/order evidence from client roles.
revoke delete on public.service_orders from authenticated;
revoke delete on public.service_offers from authenticated;
revoke delete on public.order_events from authenticated;
revoke delete on public.settlements from authenticated;
revoke delete on public.reviews from authenticated;
revoke delete on public.complaints from authenticated;

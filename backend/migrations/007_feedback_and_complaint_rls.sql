-- Sanad trust and feedback access controls
-- Apply after 005-006_secure_order_transitions_clean.sql.

-- A customer may submit one review only for their own completed order,
-- and only for the worker selected on that order.
drop policy if exists "customers can create reviews for completed own orders" on public.reviews;
create policy "customers can create reviews for completed own orders"
on public.reviews for insert
to authenticated
with check (
  customer_id = auth.uid()
  and exists (
    select 1 from public.service_orders o
    where o.id = reviews.order_id
      and o.customer_id = auth.uid()
      and o.selected_worker_id = reviews.worker_id
      and o.status in ('completed', 'awaiting_review', 'closed')
  )
);

drop policy if exists "customers can read own reviews" on public.reviews;
create policy "customers can read own reviews"
on public.reviews for select
to authenticated
using (customer_id = auth.uid());

drop policy if exists "workers can read received reviews" on public.reviews;
create policy "workers can read received reviews"
on public.reviews for select
to authenticated
using (worker_id = auth.uid());

-- A customer can open a complaint only on their own order. Operators can
-- later be granted separate moderation policies without exposing them here.
drop policy if exists "customers can create complaints for own orders" on public.complaints;
create policy "customers can create complaints for own orders"
on public.complaints for insert
to authenticated
with check (
  opened_by = auth.uid()
  and exists (
    select 1 from public.service_orders o
    where o.id = complaints.order_id
      and o.customer_id = auth.uid()
  )
);

drop policy if exists "customers can read own complaints" on public.complaints;
create policy "customers can read own complaints"
on public.complaints for select
to authenticated
using (opened_by = auth.uid());

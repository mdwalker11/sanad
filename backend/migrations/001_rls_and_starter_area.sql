-- Sanad security and starter-data migration
-- Run once in Supabase SQL Editor after backend/schema.sql.

-- Public catalog access for the mobile app.
create policy "public can read active service categories"
on public.service_categories for select
using (is_active = true);

create policy "public can read active service areas"
on public.service_areas for select
using (is_active = true);

-- Create/update the signed-in user's own profile only.
create policy "users can read own profile"
on public.profiles for select
to authenticated
using (id = auth.uid());

create policy "users can create own profile"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

create policy "users can update own profile"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- A customer can manage only their own addresses and orders.
create policy "customers can read own addresses"
on public.customer_addresses for select
to authenticated
using (customer_id = auth.uid());

create policy "customers can create own addresses"
on public.customer_addresses for insert
to authenticated
with check (customer_id = auth.uid());

create policy "customers can update own addresses"
on public.customer_addresses for update
to authenticated
using (customer_id = auth.uid())
with check (customer_id = auth.uid());

create policy "customers can read own orders"
on public.service_orders for select
to authenticated
using (customer_id = auth.uid());

create policy "customers can create own orders"
on public.service_orders for insert
to authenticated
with check (customer_id = auth.uid());

create policy "customers can update own orders"
on public.service_orders for update
to authenticated
using (customer_id = auth.uid())
with check (customer_id = auth.uid());

-- Workers can manage their own worker profile and offers.
create policy "workers can read own worker profile"
on public.worker_profiles for select
to authenticated
using (user_id = auth.uid());

create policy "workers can create own worker profile"
on public.worker_profiles for insert
to authenticated
with check (user_id = auth.uid());

create policy "workers can update own worker profile"
on public.worker_profiles for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "workers can read offers they submitted"
on public.service_offers for select
to authenticated
using (worker_id = auth.uid());

create policy "customers can read offers for own orders"
on public.service_offers for select
to authenticated
using (
  exists (
    select 1 from public.service_orders o
    where o.id = service_offers.order_id
      and o.customer_id = auth.uid()
  )
);

create policy "workers can submit own offers"
on public.service_offers for insert
to authenticated
with check (worker_id = auth.uid());

create policy "workers can update own pending offers"
on public.service_offers for update
to authenticated
using (worker_id = auth.uid() and status = 'pending')
with check (worker_id = auth.uid());

-- Starter coverage row. Additional Tripoli areas can be managed by operators later.
insert into public.service_areas
  (name_ar, name_en, municipality, coverage_status)
values
  ('طرابلس', 'Tripoli', 'Tripoli', 'active')
on conflict do nothing;

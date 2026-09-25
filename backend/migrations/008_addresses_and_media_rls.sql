-- Sanad addresses and media storage policies
-- Apply after the base schema and existing RLS migrations.

-- Address ownership is enforced at the row level.
drop policy if exists "customers manage own addresses" on public.customer_addresses;
create policy "customers manage own addresses"
on public.customer_addresses for all
to authenticated
using (customer_id = auth.uid())
with check (customer_id = auth.uid());

-- Media can be read by the order customer, assigned worker, or an operator.
drop policy if exists "participants read order media" on public.order_media;
create policy "participants read order media"
on public.order_media for select
to authenticated
using (
  uploaded_by = auth.uid()
  or exists (
    select 1 from public.service_orders o
    where o.id = order_media.order_id
      and (o.customer_id = auth.uid() or o.selected_worker_id = auth.uid())
  )
);

drop policy if exists "participants create order media" on public.order_media;
create policy "participants create order media"
on public.order_media for insert
to authenticated
with check (
  uploaded_by = auth.uid()
  and exists (
    select 1 from public.service_orders o
    where o.id = order_media.order_id
      and (o.customer_id = auth.uid() or o.selected_worker_id = auth.uid())
  )
);

-- Storage object policies for a private bucket named sanad-media.
-- The bucket must be created once in Supabase Storage before these policies run.
drop policy if exists "sanad media participants read" on storage.objects;
create policy "sanad media participants read"
on storage.objects for select
to authenticated
using (
  bucket_id = 'sanad-media'
  and (storage.foldername(name))[1] <> ''
  and exists (
    select 1 from public.service_orders o
    where o.id = ((storage.foldername(name))[2])::uuid
      and (o.customer_id = auth.uid() or o.selected_worker_id = auth.uid())
  )
);

drop policy if exists "sanad media users upload" on storage.objects;
create policy "sanad media users upload"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'sanad-media'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1 from public.service_orders o
    where o.id = ((storage.foldername(name))[2])::uuid
      and (o.customer_id = auth.uid() or o.selected_worker_id = auth.uid())
  )
);

-- Sanad operations backend: notifications and cash settlement ledger
-- Apply after 008_addresses_and_media_rls.sql.

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title_ar text not null,
  body_ar text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists notifications_recipient_idx
  on public.notifications(recipient_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists "users read own notifications" on public.notifications;
create policy "users read own notifications"
on public.notifications for select
to authenticated
using (recipient_id = auth.uid());

drop policy if exists "users mark own notifications read" on public.notifications;
create policy "users mark own notifications read"
on public.notifications for update
to authenticated
using (recipient_id = auth.uid())
with check (recipient_id = auth.uid());

drop policy if exists "operators read notifications" on public.notifications;
create policy "operators read notifications"
on public.notifications for select
to authenticated
using (
  exists (
    select 1 from public.user_roles ur
    where ur.user_id = auth.uid()
      and ur.role in ('admin', 'operator')
      and ur.is_active
  )
);

-- One settlement ledger row per completed order.
create unique index if not exists settlements_order_unique
  on public.settlements(order_id);

create or replace function public.create_cash_settlement_for_completed_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_offer public.service_offers;
  v_rate numeric(5,2);
  v_commission numeric(12,2);
begin
  if new.status = 'completed'
     and (old.status is distinct from new.status)
     and new.selected_offer_id is not null
     and new.selected_worker_id is not null
  then
    select * into v_offer
    from public.service_offers
    where id = new.selected_offer_id
      and order_id = new.id;

    if v_offer.id is not null then
      v_rate := coalesce(v_offer.commission_rate, 20.00);
      v_commission := round(coalesce(v_offer.total_amount, 0) * v_rate / 100, 2);
      insert into public.settlements (
        worker_id, order_id, gross_amount, commission_rate,
        commission_amount, worker_net_amount, amount_collected,
        status, due_at
      ) values (
        new.selected_worker_id, new.id, coalesce(v_offer.total_amount, 0),
        v_rate, v_commission,
        greatest(coalesce(v_offer.total_amount, 0) - v_commission, 0),
        null, 'due', now() + interval '7 days'
      ) on conflict (order_id) do nothing;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists create_cash_settlement_after_completion on public.service_orders;
create trigger create_cash_settlement_after_completion
after update of status on public.service_orders
for each row execute procedure public.create_cash_settlement_for_completed_order();

create or replace function public.notify_order_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status is distinct from new.status then
    insert into public.notifications(recipient_id, type, title_ar, body_ar, payload)
    values (
      new.customer_id,
      'order_status',
      'تحديث حالة الطلب',
      'تم تحديث حالة طلبك إلى: ' || new.status::text,
      jsonb_build_object('order_id', new.id, 'status', new.status)
    );

    if new.selected_worker_id is not null then
      insert into public.notifications(recipient_id, type, title_ar, body_ar, payload)
      values (
        new.selected_worker_id,
        'order_status',
        'تحديث حالة الطلب',
        'تم تحديث حالة الطلب المسند إليك إلى: ' || new.status::text,
        jsonb_build_object('order_id', new.id, 'status', new.status)
      );
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists notify_order_status_after_update on public.service_orders;
create trigger notify_order_status_after_update
after update of status on public.service_orders
for each row execute procedure public.notify_order_status_change();

-- Only operators may inspect or update settlement records.
alter table public.settlements enable row level security;
drop policy if exists "workers read own settlements" on public.settlements;
create policy "workers read own settlements"
on public.settlements for select
to authenticated
using (worker_id = auth.uid());

drop policy if exists "operators manage settlements" on public.settlements;
create policy "operators manage settlements"
on public.settlements for all
to authenticated
using (
  exists (
    select 1 from public.user_roles ur
    where ur.user_id = auth.uid()
      and ur.role in ('admin', 'operator')
      and ur.is_active
  )
)
with check (
  exists (
    select 1 from public.user_roles ur
    where ur.user_id = auth.uid()
      and ur.role in ('admin', 'operator')
      and ur.is_active
  )
);

grant select, update on public.notifications to authenticated;
grant select on public.settlements to authenticated;
grant update on public.settlements to authenticated;

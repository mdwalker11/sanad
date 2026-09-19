-- Sanad initial database schema
-- PostgreSQL / Supabase
-- Apply through Supabase SQL Editor after review.

create extension if not exists pgcrypto;

create type public.user_role as enum ('customer', 'worker', 'admin', 'operator');
create type public.account_status as enum ('active', 'pending', 'suspended', 'blocked');
create type public.worker_verification_status as enum ('pending', 'approved', 'rejected', 'suspended');
create type public.booking_type as enum ('scheduled', 'time_window', 'immediate');
create type public.order_status as enum (
  'new', 'under_review', 'awaiting_offers', 'offer_selected',
  'confirmed', 'on_the_way', 'in_progress', 'awaiting_extra_approval',
  'awaiting_completion', 'completed', 'awaiting_payment', 'paid',
  'awaiting_review', 'disputed', 'warranty', 'closed', 'cancelled'
);
create type public.offer_status as enum ('pending', 'accepted', 'rejected', 'withdrawn', 'expired');
create type public.settlement_status as enum ('due', 'grace', 'overdue', 'disputed', 'paid', 'waived');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  avatar_url text,
  preferred_language text not null default 'ar',
  status public.account_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.user_role not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (user_id, role)
);

create table public.service_categories (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  name_en text,
  slug text not null unique,
  description_ar text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.service_areas (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  name_en text,
  municipality text,
  is_active boolean not null default true,
  coverage_status text not null default 'planned',
  center_lat numeric(10,7),
  center_lng numeric(10,7),
  created_at timestamptz not null default now()
);

create table public.worker_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  verification_status public.worker_verification_status not null default 'pending',
  bio text,
  years_experience integer,
  gender text,
  has_tools boolean not null default false,
  has_transport boolean not null default false,
  availability jsonb not null default '{}'::jsonb,
  commission_rate numeric(5,2) not null default 20.00,
  settlement_day smallint not null default 1 check (settlement_day between 0 and 6),
  rating numeric(3,2) not null default 0 check (rating between 0 and 5),
  completed_orders integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.worker_documents (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  document_type text not null,
  storage_path text not null,
  status public.worker_verification_status not null default 'pending',
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.worker_services (
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  service_id uuid not null references public.service_categories(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (worker_id, service_id)
);

create table public.worker_areas (
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  area_id uuid not null references public.service_areas(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (worker_id, area_id)
);

create table public.customer_addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  label text,
  address_text text not null,
  area_id uuid references public.service_areas(id),
  latitude numeric(10,7),
  longitude numeric(10,7),
  notes text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.service_orders (
  id uuid primary key default gen_random_uuid(),
  order_number bigint generated always as identity unique,
  customer_id uuid not null references public.profiles(id),
  service_id uuid not null references public.service_categories(id),
  address_id uuid references public.customer_addresses(id),
  booking_type public.booking_type not null,
  status public.order_status not null default 'new',
  description text not null,
  preferred_start timestamptz,
  preferred_end timestamptz,
  selected_worker_id uuid references public.worker_profiles(user_id),
  selected_offer_id uuid,
  customer_total numeric(12,2),
  currency text not null default 'LYD',
  urgency_score numeric(5,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create table public.order_media (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.service_orders(id) on delete cascade,
  uploaded_by uuid not null references public.profiles(id),
  media_type text not null,
  stage text not null default 'request',
  storage_path text not null,
  created_at timestamptz not null default now()
);

create table public.service_offers (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.service_orders(id) on delete cascade,
  worker_id uuid not null references public.worker_profiles(user_id),
  status public.offer_status not null default 'pending',
  total_amount numeric(12,2) not null check (total_amount >= 0),
  visit_amount numeric(12,2) not null default 0 check (visit_amount >= 0),
  labor_amount numeric(12,2) not null default 0 check (labor_amount >= 0),
  materials_amount numeric(12,2) not null default 0 check (materials_amount >= 0),
  commission_rate numeric(5,2) not null default 20.00,
  estimated_arrival_minutes integer,
  estimated_duration_minutes integer,
  includes text,
  excludes text,
  warranty_text text,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.service_orders
  add constraint service_orders_selected_offer_fk
  foreign key (selected_offer_id) references public.service_offers(id);

create table public.extra_cost_requests (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.service_orders(id) on delete cascade,
  worker_id uuid not null references public.worker_profiles(user_id),
  amount numeric(12,2) not null check (amount >= 0),
  reason text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  approved_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  decided_at timestamptz
);

create table public.order_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.service_orders(id) on delete cascade,
  actor_id uuid references public.profiles(id),
  from_status public.order_status,
  to_status public.order_status not null,
  note text,
  created_at timestamptz not null default now()
);

create table public.settlements (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.worker_profiles(user_id),
  order_id uuid not null references public.service_orders(id),
  gross_amount numeric(12,2) not null check (gross_amount >= 0),
  commission_rate numeric(5,2) not null,
  commission_amount numeric(12,2) not null check (commission_amount >= 0),
  worker_net_amount numeric(12,2) not null check (worker_net_amount >= 0),
  amount_collected numeric(12,2),
  status public.settlement_status not null default 'due',
  due_at timestamptz not null,
  paid_at timestamptz,
  payment_reference text,
  created_at timestamptz not null default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.service_orders(id) on delete cascade,
  customer_id uuid not null references public.profiles(id),
  worker_id uuid not null references public.worker_profiles(user_id),
  rating smallint not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create table public.complaints (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.service_orders(id) on delete cascade,
  opened_by uuid not null references public.profiles(id),
  status text not null default 'open' check (status in ('open','investigating','resolved','rejected')),
  category text not null,
  description text not null,
  resolution text,
  resolved_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table public.risk_flags (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.profiles(id),
  subject_type text not null check (subject_type in ('customer','worker')),
  signal_type text not null,
  severity text not null default 'low' check (severity in ('low','medium','high','critical')),
  evidence jsonb not null default '{}'::jsonb,
  status text not null default 'open' check (status in ('open','reviewed','dismissed','actioned')),
  reviewed_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create index service_orders_customer_idx on public.service_orders(customer_id, created_at desc);
create index service_orders_status_idx on public.service_orders(status, created_at desc);
create index service_orders_service_idx on public.service_orders(service_id, status);
create index service_offers_order_idx on public.service_offers(order_id, status);
create index settlements_worker_status_idx on public.settlements(worker_id, status, due_at);
create index risk_flags_subject_idx on public.risk_flags(subject_id, status);

insert into public.service_categories (name_ar, name_en, slug, sort_order) values
  ('تنظيف المنزل', 'Home Cleaning', 'home-cleaning', 1),
  ('التكييف والتبريد', 'Cooling & AC', 'ac-cooling', 2),
  ('السباكة', 'Plumbing', 'plumbing', 3),
  ('الكهرباء', 'Electrical', 'electrical', 4),
  ('فك وتركيب الأثاث', 'Furniture Assembly', 'furniture-assembly', 5)
on conflict (slug) do nothing;

-- RLS is enabled now; policies will be added in the next migration after
-- the exact auth/user-role flows are approved and tested.
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.service_categories enable row level security;
alter table public.service_areas enable row level security;
alter table public.worker_profiles enable row level security;
alter table public.worker_documents enable row level security;
alter table public.worker_services enable row level security;
alter table public.worker_areas enable row level security;
alter table public.customer_addresses enable row level security;
alter table public.service_orders enable row level security;
alter table public.order_media enable row level security;
alter table public.service_offers enable row level security;
alter table public.extra_cost_requests enable row level security;
alter table public.order_events enable row level security;
alter table public.settlements enable row level security;
alter table public.reviews enable row level security;
alter table public.complaints enable row level security;
alter table public.risk_flags enable row level security;

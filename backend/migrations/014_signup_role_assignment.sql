-- Sanad: assign the selected signup role after email confirmation.
-- Run in Supabase SQL Editor after the existing auth profile trigger.
-- The trigger never trusts client role values beyond the two allowed signup roles.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  requested_role text;
  assigned_role public.user_role;
begin
  insert into public.profiles (id, full_name, phone, status)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    nullif(new.raw_user_meta_data ->> 'phone', ''),
    'active'
  )
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    phone = coalesce(excluded.phone, public.profiles.phone),
    updated_at = now();

  requested_role := lower(coalesce(new.raw_user_meta_data ->> 'requested_role', 'customer'));
  assigned_role := case
    when requested_role = 'worker' then 'worker'::public.user_role
    else 'customer'::public.user_role
  end;

  insert into public.user_roles (user_id, role, is_active)
  values (new.id, assigned_role, true)
  on conflict (user_id, role) do update set is_active = true;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

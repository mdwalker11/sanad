-- Sanad production order-transition migration
-- Run this once in Supabase SQL Editor.

1|-- Sanad secure order transitions
2|-- Apply after 004_worker_dispatch_rls.sql.
3|-- Prevents customers from mutating lifecycle/status fields directly.
4|
5|drop policy if exists "customers can update own orders" on public.service_orders;
6|
7|create or replace function public.worker_update_order_status(
8|  p_order_id uuid,
9|  p_to_status public.order_status
10|)
11|returns public.service_orders
12|language plpgsql
13|security definer
14|set search_path = public
15|as $$
16|declare
17|  v_order public.service_orders;
18|  v_from_status public.order_status;
19|begin
20|  select * into v_order
21|  from public.service_orders
22|  where id = p_order_id
23|    and selected_worker_id = auth.uid()
24|  for update;
25|
26|  if v_order.id is null then
27|    raise exception 'order_not_found_or_not_assigned';
28|  end if;
29|  v_from_status := v_order.status;
30|
31|  if not (
32|    (v_order.status = 'confirmed' and p_to_status = 'on_the_way') or
33|    (v_order.status = 'on_the_way' and p_to_status = 'in_progress') or
34|    (v_order.status = 'in_progress' and p_to_status = 'awaiting_completion')
35|  ) then
36|    raise exception 'invalid_worker_status_transition';
37|  end if;
38|
39|  update public.service_orders
40|  set status = p_to_status, updated_at = now()
41|  where id = p_order_id
42|  returning * into v_order;
43|
44|  insert into public.order_events(order_id, actor_id, from_status, to_status)
45|  values (p_order_id, auth.uid(), v_from_status, p_to_status);
46|
47|  return v_order;
48|end;
49|$$;
50|
51|create or replace function public.customer_complete_order(p_order_id uuid)
52|returns public.service_orders
53|language plpgsql
54|security definer
55|set search_path = public
56|as $$
57|declare
58|  v_order public.service_orders;
59|  v_from_status public.order_status;
60|begin
61|  select * into v_order
62|  from public.service_orders
63|  where id = p_order_id
64|    and customer_id = auth.uid()
65|  for update;
66|
67|  if v_order.id is null then
68|    raise exception 'order_not_found_or_not_owned';
69|  end if;
70|  v_from_status := v_order.status;
71|  if v_order.status <> 'awaiting_completion' then
72|    raise exception 'order_not_waiting_for_completion';
73|  end if;
74|
75|  update public.service_orders
76|  set status = 'completed', completed_at = now(), updated_at = now()
77|  where id = p_order_id
78|  returning * into v_order;
79|
80|  insert into public.order_events(order_id, actor_id, from_status, to_status, note)
81|  values (p_order_id, auth.uid(), v_from_status, 'completed', 'أكد العميل إنجاز الخدمة');
82|
83|  return v_order;
84|end;
85|$$;
86|
87|create or replace function public.customer_cancel_order(p_order_id uuid)
88|returns public.service_orders
89|language plpgsql
90|security definer
91|set search_path = public
92|as $$
93|declare
94|  v_order public.service_orders;
95|  v_from_status public.order_status;
96|begin
97|  select * into v_order
98|  from public.service_orders
99|  where id = p_order_id
100|    and customer_id = auth.uid()
101|  for update;
102|
103|  if v_order.id is null then
104|    raise exception 'order_not_found_or_not_owned';
105|  end if;
106|  v_from_status := v_order.status;
107|  if v_order.status not in ('new', 'under_review', 'awaiting_offers') then
108|    raise exception 'order_cannot_be_cancelled_now';
109|  end if;
110|
111|  update public.service_orders
112|  set status = 'cancelled', updated_at = now()
113|  where id = p_order_id
114|  returning * into v_order;
115|
116|  insert into public.order_events(order_id, actor_id, from_status, to_status, note)
117|  values (p_order_id, auth.uid(), v_from_status, 'cancelled', 'ألغى العميل الطلب');
118|
119|  return v_order;
120|end;
121|$$;
122|
123|create policy "approved workers can read assigned orders"
124|on public.service_orders for select
125|to authenticated
126|using (
127|  selected_worker_id = auth.uid()
128|  and exists (
129|    select 1
130|    from public.worker_profiles wp
131|    where wp.user_id = auth.uid()
132|      and wp.verification_status = 'approved'
133|  )
134|);
135|
136|
137|revoke execute on function public.worker_update_order_status(uuid, public.order_status) from public;
138|revoke execute on function public.customer_complete_order(uuid) from public;
139|revoke execute on function public.customer_cancel_order(uuid) from public;
140|grant execute on function public.worker_update_order_status(uuid, public.order_status) to authenticated;
141|grant execute on function public.customer_complete_order(uuid) to authenticated;
142|grant execute on function public.customer_cancel_order(uuid) to authenticated;

1|-- Sanad worker status controls
2|-- Apply after 005_secure_order_transitions.sql.
3|
4|create or replace function public.worker_update_order_status(
5|  p_order_id uuid,
6|  p_to_status public.order_status
7|)
8|returns public.service_orders
9|language plpgsql
10|security definer
11|set search_path = public
12|as $$
13|declare
14|  v_order public.service_orders;
15|  v_from_status public.order_status;
16|begin
17|  select * into v_order
18|  from public.service_orders
19|  where id = p_order_id
20|    and selected_worker_id = auth.uid()
21|  for update;
22|
23|  if v_order.id is null then
24|    raise exception 'order_not_found_or_not_assigned';
25|  end if;
26|  v_from_status := v_order.status;
27|
28|  if not (
29|    (v_from_status = 'confirmed' and p_to_status = 'on_the_way') or
30|    (v_from_status = 'on_the_way' and p_to_status = 'in_progress') or
31|    (v_from_status = 'in_progress' and p_to_status = 'awaiting_completion')
32|  ) then
33|    raise exception 'invalid_worker_status_transition';
34|  end if;
35|
36|  update public.service_orders
37|  set status = p_to_status, updated_at = now()
38|  where id = p_order_id
39|  returning * into v_order;
40|
41|  insert into public.order_events(order_id, actor_id, from_status, to_status)
42|  values (p_order_id, auth.uid(), v_from_status, p_to_status);
43|
44|  return v_order;
45|end;
46|$$;
47|
48|drop policy if exists "approved workers can read assigned orders" on public.service_orders;
49|
50|create policy "approved workers can read assigned orders"
51|on public.service_orders for select
52|to authenticated
53|using (
54|  selected_worker_id = auth.uid()
55|  and exists (
56|    select 1 from public.worker_profiles wp
57|    where wp.user_id = auth.uid()
58|      and wp.verification_status = 'approved'
59|  )
60|);
61|
62|revoke execute on function public.worker_update_order_status(uuid, public.order_status) from public;
63|grant execute on function public.worker_update_order_status(uuid, public.order_status) to authenticated;
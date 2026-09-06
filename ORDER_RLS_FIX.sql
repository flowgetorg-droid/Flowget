-- SparkCart Mall: Public order insert RLS fix
-- SAFE: does not delete products, orders, images, or customer data.
-- Run this ONCE in Supabase SQL Editor if the customer checkout shows
-- "new row violates row-level security policy for table orders".

alter table public.orders enable row level security;

drop policy if exists "Public can insert orders" on public.orders;
drop policy if exists "Public can submit online orders" on public.orders;

create policy "Public can insert orders"
on public.orders
for insert
 to anon, authenticated
with check (
  status = 'pending'
  and payment_method in ('Cash on Delivery','bKash','Nagad','Rocket')
  and customer_phone ~ '^01[0-9]{9}$'
);

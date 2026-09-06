-- SparkCart Mall: FEATURE-ONLY migration
-- Safe: no product/order/customer rows are deleted.
-- Run this file ONLY in Supabase SQL Editor.

-- 1) Online-payment fields on existing orders table
alter table public.orders add column if not exists payment_number text;
alter table public.orders add column if not exists payment_transaction_id text;
alter table public.orders add column if not exists payment_amount numeric(12,2);
alter table public.orders add column if not exists payment_time timestamptz;
alter table public.orders add column if not exists discount_amount numeric(12,2) not null default 0;
alter table public.orders add column if not exists coupon_code text;

-- 2) Merchant numbers used by checkout
create table if not exists public.payment_settings (
  id integer primary key check (id=1),
  bkash_number text not null default '',
  nagad_number text not null default '',
  rocket_number text not null default '',
  updated_at timestamptz not null default now()
);
insert into public.payment_settings(id) values (1) on conflict(id) do nothing;
alter table public.payment_settings enable row level security;

drop policy if exists "Public can read payment settings" on public.payment_settings;
create policy "Public can read payment settings"
on public.payment_settings for select to anon, authenticated
using (id=1);

drop policy if exists "Admin can update payment settings" on public.payment_settings;
create policy "Admin can update payment settings"
on public.payment_settings for update to authenticated
using (public.is_sparkcart_admin())
with check (public.is_sparkcart_admin());

-- 3) Allow Rocket in addition to the existing public order flow.
-- This policy is additive and does not remove your existing policy.
drop policy if exists "Public can submit online orders" on public.orders;
create policy "Public can submit online orders"
on public.orders for insert to anon
with check (
  status='pending'
  and payment_method in ('bKash','Nagad','Rocket')
  and customer_phone ~ '^01[0-9]{9}$'
);

-- 4) Enforce payment details server-side for all online payments.
-- This prevents an online order from being inserted without the payment info.
create or replace function public.validate_sparkcart_payment()
returns trigger
language plpgsql
as $$
begin
  if new.payment_method in ('bKash','Nagad','Rocket') then
    if coalesce(trim(new.payment_number),'') = '' then
      raise exception 'Payment number is required for online payment';
    end if;
    if new.payment_amount is null or new.payment_amount < 0 then
      raise exception 'Payment amount is required for online payment';
    end if;
    if new.payment_time is null then
      raise exception 'Payment time is required for online payment';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_validate_sparkcart_payment on public.orders;
create trigger trg_validate_sparkcart_payment
before insert or update on public.orders
for each row execute function public.validate_sparkcart_payment();

-- 5) Customer tracking RPC: requires BOTH Order ID and phone.
create or replace function public.track_order(p_order_id text, p_customer_phone text)
returns table(
  order_id text,
  customer_name text,
  district text,
  upazila text,
  total_amount numeric,
  status text,
  created_at timestamptz
)
language sql
security definer
set search_path=public
as $$
  select o.order_id,o.customer_name,o.district,o.upazila,o.total_amount,o.status,o.created_at
  from public.orders o
  where upper(o.order_id)=upper(trim(p_order_id))
    and o.customer_phone=trim(p_customer_phone)
  limit 1;
$$;
revoke all on function public.track_order(text,text) from public;
grant execute on function public.track_order(text,text) to anon, authenticated;

create index if not exists orders_payment_method_idx on public.orders(payment_method);
create index if not exists orders_payment_time_idx on public.orders(payment_time desc);

-- 6) Helpful read indexes
create index if not exists orders_district_idx on public.orders(district);
create index if not exists orders_order_id_idx on public.orders(order_id);

-- IMPORTANT:
-- Do NOT run supabase.sql after this migration just to get the features.
-- supabase.sql contains the product seed and can change catalog prices/details.


-- 7) Marketplace brand filter support
alter table public.products add column if not exists brand text default '';
create index if not exists products_brand_idx on public.products(brand);

-- NOTE: This upgrade adds the brand filtering.
-- Real debit/credit card processing still requires a licensed payment gateway account/API; card numbers should never be stored in this database.

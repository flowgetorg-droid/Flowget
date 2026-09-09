-- FlowGet FINAL Supabase schema
-- Fresh install / safe rerun
-- Run this entire file in Supabase SQL Editor.

create extension if not exists pgcrypto;

-- =========================================================
-- 1. TABLES
-- =========================================================

create table if not exists public.website_settings (
  id boolean primary key default true,
  store_name text not null default 'FlowGet',
  tagline text,
  logo_url text,
  mobile_logo_url text,
  favicon_url text,
  browser_title text,
  meta_description text,
  search_placeholder text default 'Search products...',
  footer_about text,
  phone text,
  email text,
  "primary" text default '#f97316',
  primary_hover text default '#ea580c',
  secondary text default '#111827',
  delivery_dhaka numeric default 80,
  delivery_outside numeric default 140,
  currency text default '৳',
  updated_at timestamptz default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  icon text,
  image_url text,
  description text,
  short_description text,
  seo_title text,
  seo_description text,
  sort_order int default 0,
  active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  description text,
  specifications jsonb default '{}'::jsonb,
  category_id uuid references public.categories(id) on delete set null,
  brand text,
  sku text unique,
  price numeric not null default 0 check(price >= 0),
  discount_price numeric check(discount_price is null or discount_price >= 0),
  effective_price numeric generated always as (coalesce(discount_price, price)) stored,
  stock int not null default 0 check(stock >= 0),
  main_image text,
  video_url text,
  rating numeric default 0,
  review_count int default 0,
  featured boolean default false,
  new_arrival boolean default false,
  flash_deal boolean default false,
  is_best_selling boolean default false,
  active boolean default true,
  seo_title text,
  meta_description text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  url text not null,
  sort_order int default 0,
  created_at timestamptz default now()
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text,
  phone text unique,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  coupon_type text not null check(coupon_type in ('percentage','fixed')),
  discount_value numeric not null,
  min_order numeric default 0,
  max_discount numeric,
  usage_limit int,
  per_customer_limit int default 1,
  start_at timestamptz,
  expires_at timestamptz,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_id text unique not null,
  customer_id uuid references public.customers(id),
  customer_name text not null,
  phone text not null,
  division text,
  district text,
  area text,
  address text not null,
  note text,
  subtotal numeric not null,
  discount numeric default 0,
  coupon_code text,
  delivery_charge numeric not null,
  payment_method text not null,
  total numeric not null,
  status text not null default 'Pending'
    check(status in ('Pending','Confirmed','Processing','Shipped','Delivered','Cancelled')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id),
  product_name text not null,
  sku text,
  quantity int not null check(quantity > 0),
  unit_price numeric not null,
  line_total numeric not null
);

create table if not exists public.coupon_usage (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid not null references public.coupons(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  phone text not null,
  discount numeric not null,
  created_at timestamptz default now(),
  unique(coupon_id, order_id)
);

create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(),
  title text,
  subtitle text,
  button_text text,
  button_url text,
  image_url text,
  mobile_image_url text,
  start_at timestamptz,
  end_at timestamptz,
  sort_order int default 0,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.advertisements (
  id uuid primary key default gen_random_uuid(),
  title text,
  text_content text,
  image_url text,
  cta_text text,
  destination_url text,
  placement text,
  start_at timestamptz,
  end_at timestamptz,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.homepage_sections (
  id uuid primary key default gen_random_uuid(),
  section_type text not null,
  title text,
  subtitle text,
  config jsonb default '{}'::jsonb,
  sort_order int default 0,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  account_number text,
  merchant_number text,
  instructions text,
  transaction_instructions text,
  active boolean default false,
  sort_order int default 0
);

create table if not exists public.navigation_items (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  url text not null,
  sort_order int default 0,
  active boolean default true
);

create table if not exists public.pages (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  content text,
  seo_title text,
  meta_description text,
  active boolean default true,
  updated_at timestamptz default now()
);

create table if not exists public.analytics_events (
  id bigint generated always as identity primary key,
  event_name text not null,
  path text,
  product_id uuid references public.products(id) on delete set null,
  metadata jsonb default '{}'::jsonb,
  session_id text,
  created_at timestamptz default now()
);

create table if not exists public.visitor_sessions (
  id text primary key,
  started_at timestamptz default now(),
  ended_at timestamptz,
  device_type text,
  referrer text,
  last_path text
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete cascade,
  customer_name text,
  rating int check(rating between 1 and 5),
  review_text text,
  approved boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

create table if not exists public.order_counters (
  order_date date primary key,
  last_number int not null default 0
);

-- =========================================================
-- 2. MIGRATE EXISTING / PARTIAL DATABASES
-- =========================================================

alter table public.products add column if not exists category_id uuid;
alter table public.products add column if not exists specifications jsonb default '{}'::jsonb;
alter table public.products add column if not exists brand text;
alter table public.products add column if not exists sku text;
alter table public.products add column if not exists price numeric default 0;
alter table public.products add column if not exists discount_price numeric;
alter table public.products add column if not exists stock int default 0;
alter table public.products add column if not exists main_image text;
alter table public.products add column if not exists rating numeric default 0;
alter table public.products add column if not exists review_count int default 0;
alter table public.products add column if not exists featured boolean default false;
alter table public.products add column if not exists new_arrival boolean default false;
alter table public.products add column if not exists flash_deal boolean default false;
alter table public.products add column if not exists is_best_selling boolean default false;
alter table public.products add column if not exists active boolean default true;
alter table public.products add column if not exists seo_title text;
alter table public.products add column if not exists meta_description text;
alter table public.products add column if not exists created_at timestamptz default now();
alter table public.products add column if not exists updated_at timestamptz default now();
alter table public.products add column if not exists video_url text;

-- Preserve legacy category values when an older products.category text column exists.
do $$
begin
  if exists (
    select 1 from pg_attribute
    where attrelid='public.products'::regclass
      and attname='category'
      and not attisdropped
  ) then
    execute $legacy$
      update public.products p
      set category_id=c.id
      from public.categories c
      where p.category_id is null
        and p.category is not null
        and (lower(c.name)=lower(p.category) or lower(c.slug)=lower(p.category))
    $legacy$;
  end if;
exception when undefined_column then null;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'products_category_id_fkey'
      and conrelid = 'public.products'::regclass
  ) then
    alter table public.products
      add constraint products_category_id_fkey
      foreign key(category_id) references public.categories(id)
      on delete set null;
  end if;
exception when duplicate_object then null;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_attribute
    where attrelid = 'public.products'::regclass
      and attname = 'effective_price'
      and not attisdropped
  ) then
    alter table public.products
      add column effective_price numeric
      generated always as (coalesce(discount_price, price)) stored;
  end if;
end $$;

alter table public.website_settings add column if not exists "primary" text default '#f97316';
alter table public.website_settings add column if not exists primary_hover text default '#ea580c';
alter table public.website_settings add column if not exists secondary text default '#111827';
alter table public.website_settings add column if not exists delivery_dhaka numeric default 80;
alter table public.website_settings add column if not exists delivery_outside numeric default 140;
alter table public.website_settings add column if not exists currency text default '৳';
alter table public.coupons add column if not exists per_customer_limit int default 1;
alter table public.banners add column if not exists mobile_image_url text;

insert into public.website_settings(id)
values(true)
on conflict(id) do nothing;

-- Ensure coupon columns exist before constraints/functions use them.
alter table public.coupons add column if not exists code text;
alter table public.coupons add column if not exists coupon_type text;
alter table public.coupons add column if not exists discount_value numeric;
alter table public.coupons add column if not exists min_order numeric default 0;
alter table public.coupons add column if not exists max_discount numeric;
alter table public.coupons add column if not exists usage_limit int;
alter table public.coupons add column if not exists per_customer_limit int default 1;
alter table public.coupons add column if not exists start_at timestamptz;
alter table public.coupons add column if not exists expires_at timestamptz;
alter table public.coupons add column if not exists active boolean default true;
alter table public.coupons add column if not exists created_at timestamptz default now();

-- Compatibility columns for older FlowGet databases. These additions do not delete or overwrite existing order data.
alter table public.orders add column if not exists customer_phone text;
alter table public.orders add column if not exists email text;
alter table public.orders add column if not exists address text;
alter table public.orders add column if not exists full_address text;
alter table public.orders add column if not exists upazila text;
alter table public.orders add column if not exists notes text;
alter table public.orders add column if not exists total_amount numeric;
alter table public.orders add column if not exists payment_status text;
alter table public.orders add column if not exists transaction_id text;
alter table public.orders add column if not exists order_id text;
alter table public.orders add column if not exists customer_id uuid;
alter table public.orders add column if not exists customer_name text;
alter table public.orders add column if not exists phone text;
alter table public.orders add column if not exists division text;
alter table public.orders add column if not exists district text;
alter table public.orders add column if not exists area text;
alter table public.orders add column if not exists subtotal numeric;
alter table public.orders add column if not exists discount numeric default 0;
alter table public.orders add column if not exists coupon_code text;
alter table public.orders add column if not exists delivery_charge numeric;
alter table public.orders add column if not exists payment_method text;
alter table public.orders add column if not exists total numeric;
alter table public.orders add column if not exists status text default 'Pending';
alter table public.orders add column if not exists created_at timestamptz default now();
alter table public.orders add column if not exists updated_at timestamptz default now();


-- Copy legacy order fields into the current canonical fields only when the current field is empty.
update public.orders
set phone=coalesce(nullif(phone,''),nullif(customer_phone,'')),
    address=coalesce(nullif(address,''),nullif(full_address,'')),
    area=coalesce(nullif(area,''),nullif(upazila,'')),
    note=coalesce(nullif(note,''),nullif(notes,'')),
    total=coalesce(total,total_amount)
where (phone is null or phone='')
   or (address is null or address='')
   or (area is null or area='')
   or (note is null or note='')
   or total is null;

-- Normalize legacy order status values without touching order rows other than the status text itself.
do $$
begin
  for r in
    select conname
    from pg_constraint
    where conrelid='public.orders'::regclass
      and contype='c'
      and pg_get_constraintdef(oid) ilike '%status%'
  loop
    execute format('alter table public.orders drop constraint %I',r.conname);
  end loop;
exception when undefined_table then null;
end $$;

update public.orders
set status=case lower(trim(coalesce(status,'')))
  when 'pending' then 'Pending'
  when 'confirmed' then 'Confirmed'
  when 'processing' then 'Processing'
  when 'shipped' then 'Shipped'
  when 'delivered' then 'Delivered'
  when 'cancelled' then 'Cancelled'
  when 'canceled' then 'Cancelled'
  else 'Pending'
end;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='orders_status_check_flowget'
      and conrelid='public.orders'::regclass
  ) then
    alter table public.orders add constraint orders_status_check_flowget
      check(status in ('Pending','Confirmed','Processing','Shipped','Delivered','Cancelled'));
  end if;
end $$;

-- =========================================================
-- 3. CONSTRAINTS / INDEXES
-- =========================================================

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='products_discount_not_above_price'
      and conrelid='public.products'::regclass
  ) then
    alter table public.products
      add constraint products_discount_not_above_price
      check(discount_price is null or discount_price <= price);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='coupons_positive_discount'
      and conrelid='public.coupons'::regclass
  ) then
    alter table public.coupons
      add constraint coupons_positive_discount
      check(discount_value > 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='website_delivery_dhaka_nonnegative'
      and conrelid='public.website_settings'::regclass
  ) then
    alter table public.website_settings
      add constraint website_delivery_dhaka_nonnegative
      check(delivery_dhaka >= 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='website_delivery_outside_nonnegative'
      and conrelid='public.website_settings'::regclass
  ) then
    alter table public.website_settings
      add constraint website_delivery_outside_nonnegative
      check(delivery_outside >= 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='coupons_min_order_nonnegative'
      and conrelid='public.coupons'::regclass
  ) then
    alter table public.coupons
      add constraint coupons_min_order_nonnegative
      check(min_order >= 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='coupons_max_discount_positive'
      and conrelid='public.coupons'::regclass
  ) then
    alter table public.coupons
      add constraint coupons_max_discount_positive
      check(max_discount is null or max_discount >= 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='coupons_usage_limit_positive'
      and conrelid='public.coupons'::regclass
  ) then
    alter table public.coupons
      add constraint coupons_usage_limit_positive
      check(usage_limit is null or usage_limit > 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='coupons_customer_limit_positive'
      and conrelid='public.coupons'::regclass
  ) then
    alter table public.coupons
      add constraint coupons_customer_limit_positive
      check(per_customer_limit is null or per_customer_limit > 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='coupons_dates_valid'
      and conrelid='public.coupons'::regclass
  ) then
    alter table public.coupons
      add constraint coupons_dates_valid
      check(expires_at is null or start_at is null or expires_at >= start_at);
  end if;
end $$;

create index if not exists products_category_idx on public.products(category_id);
create index if not exists products_active_idx on public.products(active);
create index if not exists products_effective_price_idx on public.products(effective_price);
create index if not exists orders_phone_idx on public.orders(phone);
create index if not exists orders_status_idx on public.orders(status);
create index if not exists analytics_events_created_idx on public.analytics_events(created_at);
create index if not exists product_images_product_idx on public.product_images(product_id);
create index if not exists coupon_usage_coupon_phone_idx on public.coupon_usage(coupon_id,phone);

-- =========================================================
-- 4. FUNCTIONS
-- =========================================================

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1
    from public.admin_users
    where user_id = auth.uid()
  )
$$;

create or replace function public.next_order_id()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  d date := current_date;
  n int;
begin
  insert into public.order_counters(order_date,last_number)
  values(d,1)
  on conflict(order_date)
  do update set last_number = public.order_counters.last_number + 1
  returning last_number into n;

  return 'FG-' || to_char(d,'YYYYMMDD') || '-' || lpad(n::text,6,'0');
end
$$;

create or replace function public.track_order(
  p_order_id text,
  p_phone text
)
returns table(order_id text,status text,created_at timestamptz)
language sql
security definer
set search_path = public
as $$
  select o.order_id,o.status,o.created_at
  from public.orders o
  where upper(o.order_id)=upper(trim(p_order_id))
    and regexp_replace(o.phone,'[^0-9]','','g')
      = regexp_replace(trim(p_phone),'[^0-9]','','g')
  limit 1
$$;

create or replace function public.create_order_secure(
  p_customer_name text,
  p_phone text,
  p_division text,
  p_district text,
  p_area text,
  p_address text,
  p_note text,
  p_items jsonb,
  p_coupon text,
  p_delivery_area text,
  p_payment_method text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  item jsonb;
  p public.products%rowtype;
  o public.orders%rowtype;
  sub numeric := 0;
  disc numeric := 0;
  del numeric := 0;
  cp public.coupons%rowtype;
  qty int;
  oid text;
  cust uuid;
  clean_phone text := regexp_replace(trim(coalesce(p_phone,'')),'[^0-9]','','g');
begin
  if length(trim(coalesce(p_customer_name,''))) < 2 then
    raise exception 'Please enter your name';
  end if;

  if clean_phone !~ '^01[0-9]{9}$' then
    raise exception 'Invalid Bangladesh phone number';
  end if;

  if jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items)=0 then
    raise exception 'Cart is empty';
  end if;

  if lower(trim(coalesce(p_payment_method,''))) <> 'cash on delivery' then
    raise exception 'Invalid payment method';
  end if;

  -- Validate and lock all requested products.
  for item in select * from jsonb_array_elements(p_items) loop
    begin
      qty := (item->>'quantity')::int;
    exception when others then
      raise exception 'Invalid quantity';
    end;

    if qty < 1 then
      raise exception 'Invalid quantity';
    end if;

    begin
      select *
      into p
      from public.products
      where id=(item->>'product_id')::uuid
        and active=true
      for update;
    exception when invalid_text_representation then
      raise exception 'Invalid product';
    end;

    if not found then
      raise exception 'Product unavailable';
    end if;

    if qty > p.stock then
      raise exception 'Insufficient stock for %',p.name;
    end if;

    sub := sub + coalesce(p.discount_price,p.price) * qty;
  end loop;

  if p_coupon is not null and trim(p_coupon) <> '' then
    select *
    into cp
    from public.coupons
    where upper(code)=upper(trim(p_coupon))
      and active=true
      and (start_at is null or now() >= start_at)
      and (expires_at is null or now() <= expires_at)
    for update;

    if not found then
      raise exception 'Invalid coupon';
    end if;

    if sub < coalesce(cp.min_order,0) then
      raise exception 'Minimum order amount not reached';
    end if;

    if cp.usage_limit is not null
       and (
         select count(*)
         from public.coupon_usage
         where coupon_id=cp.id
       ) >= cp.usage_limit then
      raise exception 'Coupon usage limit exceeded';
    end if;

    if cp.per_customer_limit is not null
       and (
         select count(*)
         from public.coupon_usage
         where coupon_id=cp.id
           and phone=clean_phone
       ) >= cp.per_customer_limit then
      raise exception 'This coupon has reached its limit for this customer';
    end if;

    if cp.coupon_type='percentage' then
      disc := least(
        sub * cp.discount_value / 100,
        coalesce(cp.max_discount,sub)
      );
    else
      disc := least(cp.discount_value,sub);
    end if;
  end if;

  select
    case
      when lower(trim(coalesce(p_delivery_area,'')))='dhaka'
      then delivery_dhaka
      else delivery_outside
    end
  into del
  from public.website_settings
  where id=true;

  del := coalesce(del,0);

  oid := public.next_order_id();

  insert into public.customers(name,phone)
  values(p_customer_name,clean_phone)
  on conflict(phone)
  do update set name=excluded.name,updated_at=now()
  returning id into cust;

  insert into public.orders(
    order_id,customer_id,customer_name,phone,division,district,area,
    address,note,subtotal,discount,coupon_code,delivery_charge,
    payment_method,total
  )
  values(
    oid,cust,p_customer_name,clean_phone,p_division,p_district,p_area,
    p_address,p_note,sub,disc,nullif(trim(p_coupon),''),
    del,'Cash on Delivery',sub-disc+del
  )
  returning * into o;

  for item in select * from jsonb_array_elements(p_items) loop
    select *
    into p
    from public.products
    where id=(item->>'product_id')::uuid
    for update;

    qty := (item->>'quantity')::int;

    insert into public.order_items(
      order_id,product_id,product_name,sku,quantity,unit_price,line_total
    )
    values(
      o.id,p.id,p.name,p.sku,qty,
      coalesce(p.discount_price,p.price),
      coalesce(p.discount_price,p.price)*qty
    );

    update public.products
    set stock=stock-qty,updated_at=now()
    where id=p.id;
  end loop;

  if cp.id is not null then
    insert into public.coupon_usage(
      coupon_id,order_id,phone,discount
    )
    values(cp.id,o.id,clean_phone,disc);
  end if;

  return jsonb_build_object(
    'id',o.id,
    'order_id',o.order_id,
    'total',o.total,
    'status',o.status
  );
end
$$;

create or replace function public.cancel_order_secure(
  p_order_uuid uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders%rowtype;
  i record;
  p public.products%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Not authorized';
  end if;

  select *
  into o
  from public.orders
  where id=p_order_uuid
  for update;

  if not found then
    raise exception 'Order not found';
  end if;

  if o.status='Cancelled' then
    return jsonb_build_object('id',o.id,'status',o.status);
  end if;

  if o.status='Delivered' then
    raise exception 'Delivered orders cannot be cancelled';
  end if;

  for i in
    select product_id,quantity
    from public.order_items
    where order_id=o.id
  loop
    select *
    into p
    from public.products
    where id=i.product_id
    for update;

    if found then
      update public.products
      set stock=stock+i.quantity,updated_at=now()
      where id=p.id;
    end if;
  end loop;

  update public.orders
  set status='Cancelled',updated_at=now()
  where id=o.id;

  return jsonb_build_object(
    'id',o.id,
    'status','Cancelled'
  );
end
$$;

create or replace function public.update_order_status_secure(
  p_order_uuid uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders%rowtype;
  current_rank int;
  new_rank int;
begin
  if not public.is_admin() then
    raise exception 'Not authorized';
  end if;

  if p_status not in (
    'Pending','Confirmed','Processing','Shipped','Delivered','Cancelled'
  ) then
    raise exception 'Invalid order status';
  end if;

  if p_status='Cancelled' then
    return public.cancel_order_secure(p_order_uuid);
  end if;

  select *
  into o
  from public.orders
  where id=p_order_uuid
  for update;

  if not found then
    raise exception 'Order not found';
  end if;

  if o.status='Cancelled' then
    raise exception 'Cancelled orders cannot be reopened';
  end if;

  if o.status='Delivered' then
    raise exception 'Delivered orders cannot be changed';
  end if;

  current_rank := case o.status
    when 'Pending' then 1
    when 'Confirmed' then 2
    when 'Processing' then 3
    when 'Shipped' then 4
    when 'Delivered' then 5
    else 0
  end;

  new_rank := case p_status
    when 'Pending' then 1
    when 'Confirmed' then 2
    when 'Processing' then 3
    when 'Shipped' then 4
    when 'Delivered' then 5
    else 0
  end;

  if new_rank < current_rank then
    raise exception 'Order status cannot move backwards';
  end if;

  update public.orders
  set status=p_status,updated_at=now()
  where id=o.id;

  return jsonb_build_object(
    'id',o.id,
    'status',p_status
  );
end
$$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at=now();
  return new;
end
$$;

-- =========================================================
-- 5. RLS
-- =========================================================

alter table public.website_settings enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.banners enable row level security;
alter table public.advertisements enable row level security;
alter table public.homepage_sections enable row level security;
alter table public.payment_methods enable row level security;
alter table public.navigation_items enable row level security;
alter table public.pages enable row level security;
alter table public.reviews enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.coupons enable row level security;
alter table public.coupon_usage enable row level security;
alter table public.analytics_events enable row level security;
alter table public.visitor_sessions enable row level security;
alter table public.admin_users enable row level security;
alter table public.customers enable row level security;
alter table public.order_counters enable row level security;

-- Remove policies that may exist from previous partial runs.
drop policy if exists "public settings read" on public.website_settings;
drop policy if exists "public categories read" on public.categories;
drop policy if exists "public products read" on public.products;
drop policy if exists "public images read" on public.product_images;
drop policy if exists "public banners read" on public.banners;
drop policy if exists "public ads read" on public.advertisements;
drop policy if exists "public homepage read" on public.homepage_sections;
drop policy if exists "public pages read" on public.pages;
drop policy if exists "public reviews read" on public.reviews;
drop policy if exists "admin all settings" on public.website_settings;
drop policy if exists "admin all categories" on public.categories;
drop policy if exists "admin all products" on public.products;
drop policy if exists "admin all images" on public.product_images;
drop policy if exists "admin all banners" on public.banners;
drop policy if exists "admin all ads" on public.advertisements;
drop policy if exists "admin all homepage" on public.homepage_sections;
drop policy if exists "admin all payments" on public.payment_methods;
drop policy if exists "admin all navigation" on public.navigation_items;
drop policy if exists "admin all pages" on public.pages;
drop policy if exists "admin all reviews" on public.reviews;
drop policy if exists "admin select orders" on public.orders;
drop policy if exists "admin all orders" on public.orders;
drop policy if exists "admin select items" on public.order_items;
drop policy if exists "admin all coupons" on public.coupons;
drop policy if exists "admin all coupon usage" on public.coupon_usage;
drop policy if exists "admin analytics" on public.analytics_events;
drop policy if exists "public analytics insert" on public.analytics_events;
drop policy if exists "admin sessions" on public.visitor_sessions;
drop policy if exists "public session insert" on public.visitor_sessions;
drop policy if exists "admin customers" on public.customers;
drop policy if exists "admin admins" on public.admin_users;
drop policy if exists "admin counters" on public.order_counters;

-- Public read policies.
create policy "public settings read"
on public.website_settings for select
using(true);

create policy "public categories read"
on public.categories for select
using(active=true);

create policy "public products read"
on public.products for select
using(active=true);

create policy "public images read"
on public.product_images for select
using(
  exists(
    select 1 from public.products p
    where p.id=product_images.product_id
      and p.active=true
  )
);

create policy "public banners read"
on public.banners for select
using(active=true);

create policy "public ads read"
on public.advertisements for select
using(active=true);

create policy "public homepage read"
on public.homepage_sections for select
using(active=true);

create policy "public pages read"
on public.pages for select
using(active=true);

create policy "public reviews read"
on public.reviews for select
using(approved=true);

-- Admin policies.
create policy "admin all settings"
on public.website_settings for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all categories"
on public.categories for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all products"
on public.products for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all images"
on public.product_images for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all banners"
on public.banners for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all ads"
on public.advertisements for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all homepage"
on public.homepage_sections for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all payments"
on public.payment_methods for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all navigation"
on public.navigation_items for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all pages"
on public.pages for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all reviews"
on public.reviews for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin select orders"
on public.orders for select
using(public.is_admin());

create policy "admin select items"
on public.order_items for select
using(public.is_admin());

create policy "admin all coupons"
on public.coupons for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin all coupon usage"
on public.coupon_usage for select
using(public.is_admin());

create policy "admin analytics"
on public.analytics_events for select
using(public.is_admin());

create policy "public analytics insert"
on public.analytics_events for insert
with check(true);

create policy "admin sessions"
on public.visitor_sessions for all
using(public.is_admin())
with check(public.is_admin());

create policy "public session insert"
on public.visitor_sessions for insert
with check(true);

create policy "admin customers"
on public.customers for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin admins"
on public.admin_users for all
using(public.is_admin())
with check(public.is_admin());

create policy "admin counters"
on public.order_counters for select
using(public.is_admin());

-- =========================================================
-- 6. TRIGGERS
-- =========================================================

drop trigger if exists categories_touch_updated_at on public.categories;
create trigger categories_touch_updated_at
before update on public.categories
for each row execute function public.touch_updated_at();

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at
before update on public.products
for each row execute function public.touch_updated_at();

drop trigger if exists customers_touch_updated_at on public.customers;
create trigger customers_touch_updated_at
before update on public.customers
for each row execute function public.touch_updated_at();

drop trigger if exists orders_touch_updated_at on public.orders;
create trigger orders_touch_updated_at
before update on public.orders
for each row execute function public.touch_updated_at();

drop trigger if exists pages_touch_updated_at on public.pages;
create trigger pages_touch_updated_at
before update on public.pages
for each row execute function public.touch_updated_at();

-- =========================================================
-- 7. FUNCTION PERMISSIONS
-- =========================================================

revoke all on function public.next_order_id() from public;
revoke all on function public.next_order_id() from anon;
revoke all on function public.next_order_id() from authenticated;

revoke all on function public.track_order(text,text) from public;
grant execute on function public.track_order(text,text) to anon, authenticated;

revoke all on function public.create_order_secure(
  text,text,text,text,text,text,text,jsonb,text,text,text
) from public;
grant execute on function public.create_order_secure(
  text,text,text,text,text,text,text,jsonb,text,text,text
) to anon, authenticated;

revoke all on function public.cancel_order_secure(uuid) from public;
grant execute on function public.cancel_order_secure(uuid) to authenticated;

revoke all on function public.update_order_status_secure(uuid,text) from public;
grant execute on function public.update_order_status_secure(uuid,text) to authenticated;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- =========================================================
-- 8. BASIC DATA
-- =========================================================

insert into public.website_settings(
  id,store_name,tagline,currency,delivery_dhaka,delivery_outside
)
values(
  true,'FlowGet','Quality products delivered across Bangladesh',
  '৳',80,140
)
on conflict(id) do nothing;


-- =========================================================
-- 9. VISITOR ANALYTICS
-- =========================================================

alter table if exists public.visitor_sessions
  add column if not exists last_seen_at timestamptz default now();

create index if not exists visitor_sessions_last_seen_idx
  on public.visitor_sessions(last_seen_at);

create or replace function public.track_visitor_session(
  p_session_id text,
  p_path text,
  p_device_type text default null,
  p_referrer text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if p_session_id is null or length(trim(p_session_id)) < 8 then
    raise exception 'Invalid visitor session';
  end if;

  insert into public.visitor_sessions(id,started_at,last_seen_at,device_type,referrer,last_path)
  values(p_session_id,now(),now(),left(p_device_type,20),left(p_referrer,500),left(coalesce(p_path,'/'),500))
  on conflict(id) do update set
    last_seen_at=now(),
    ended_at=null,
    device_type=coalesce(excluded.device_type,public.visitor_sessions.device_type),
    referrer=coalesce(public.visitor_sessions.referrer,excluded.referrer),
    last_path=excluded.last_path;
end
$$;

revoke all on function public.track_visitor_session(text,text,text,text) from public;
grant execute on function public.track_visitor_session(text,text,text,text) to anon, authenticated;

-- =========================================================
-- DONE
-- =========================================================

-- FlowGet media upload support
alter table public.products add column if not exists video_url text;

insert into storage.buckets (id, name, public)
values ('product-media','product-media',true)
on conflict (id) do update set public=true;

drop policy if exists "public product media read" on storage.objects;
create policy "public product media read"
on storage.objects for select
using (bucket_id='product-media');

drop policy if exists "admin product media insert" on storage.objects;
create policy "admin product media insert"
on storage.objects for insert to authenticated
with check (bucket_id='product-media' and public.is_admin());

drop policy if exists "admin product media update" on storage.objects;
create policy "admin product media update"
on storage.objects for update to authenticated
using (bucket_id='product-media' and public.is_admin())
with check (bucket_id='product-media' and public.is_admin());

drop policy if exists "admin product media delete" on storage.objects;
create policy "admin product media delete"
on storage.objects for delete to authenticated
using (bucket_id='product-media' and public.is_admin());


-- FlowGet banner image upload support
insert into storage.buckets (id, name, public)
values ('banner-media','banner-media',true)
on conflict (id) do update set public=true;

drop policy if exists "public banner media read" on storage.objects;
create policy "public banner media read"
on storage.objects for select
using (bucket_id='banner-media');

drop policy if exists "admin banner media insert" on storage.objects;
create policy "admin banner media insert"
on storage.objects for insert to authenticated
with check (bucket_id='banner-media' and public.is_admin());

drop policy if exists "admin banner media update" on storage.objects;
create policy "admin banner media update"
on storage.objects for update to authenticated
using (bucket_id='banner-media' and public.is_admin())
with check (bucket_id='banner-media' and public.is_admin());

drop policy if exists "admin banner media delete" on storage.objects;
create policy "admin banner media delete"
on storage.objects for delete to authenticated
using (bucket_id='banner-media' and public.is_admin());

-- =========================================================
-- 9. PRODUCT MEDIA + DEMO CATALOG MIGRATION
-- =========================================================
-- See FlowGet_Product_Catalog_And_Image_Fix.sql for the same safe migration/seed script.

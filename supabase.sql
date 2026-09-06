-- SparkCart Mall: complete database setup for Customer + Mobile Admin
create extension if not exists pgcrypto;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_id text unique not null,
  customer_name text not null,
  customer_phone text not null,
  customer_email text,
  division text not null,
  district text not null,
  upazila text not null,
  union_or_area text,
  full_address text not null,
  delivery_note text,
  payment_method text not null default 'Cash on Delivery',
  subtotal numeric(12,2) not null check (subtotal >= 0),
  delivery_charge numeric(12,2) not null check (delivery_charge >= 0),
  total_amount numeric(12,2) not null check (total_amount >= 0),
  order_items jsonb not null,
  status text not null default 'pending'
    check (status in ('pending','confirmed','processing','shipped','delivered','cancelled')),
  created_at timestamptz not null default now()
);

create index if not exists orders_created_at_idx on public.orders(created_at desc);
create index if not exists orders_status_idx on public.orders(status);
alter table public.orders enable row level security;

drop policy if exists "Public can insert orders" on public.orders;
create policy "Public can insert orders" on public.orders
for insert to anon
with check (
  status='pending'
  and payment_method in ('Cash on Delivery','bKash','Nagad')
  and customer_phone ~ '^01[0-9]{9}$'
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text not null,
  price numeric(12,2) not null check (price >= 0),
  old_price numeric(12,2) not null default 0 check (old_price >= 0),
  discount numeric(6,2) not null default 0,
  rating numeric(3,2) not null default 0,
  reviews integer not null default 0,
  image text,
  stock integer not null default 0 check (stock >= 0),
  badge text default '',
  featured boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  details text default '',
  specifications text default '',
  sku text default '',
  video_url text,
  images jsonb not null default '[]'::jsonb,
  colors jsonb not null default '[]'::jsonb,
  sizes jsonb not null default '[]'::jsonb
);
alter table public.products enable row level security;

-- Step 1 product-system fields for existing databases
alter table public.products add column if not exists details text default '';
alter table public.products add column if not exists specifications text default '';
alter table public.products add column if not exists sku text default '';
alter table public.products add column if not exists video_url text;
alter table public.products add column if not exists images jsonb not null default '[]'::jsonb;
alter table public.products add column if not exists colors jsonb not null default '[]'::jsonb;
alter table public.products add column if not exists sizes jsonb not null default '[]'::jsonb;
alter table public.products add column if not exists seo_title text default '';
alter table public.products add column if not exists meta_description text default '';
alter table public.products add column if not exists low_stock_threshold integer not null default 5 check (low_stock_threshold >= 0);

drop policy if exists "Public can read active products" on public.products;
create policy "Public can read active products" on public.products
for select to anon, authenticated using (active=true);

-- Admin table and helper
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;

create or replace function public.is_sparkcart_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists (
    select 1 from public.admin_users a
    where a.user_id=auth.uid()
      and lower(a.email)=lower(coalesce(auth.jwt()->>'email',''))
  );
$$;
revoke all on function public.is_sparkcart_admin() from public;
grant execute on function public.is_sparkcart_admin() to authenticated;

-- Add the existing Auth user as admin. If the user has not been created yet,
-- create it first in Supabase Authentication > Users.
insert into public.admin_users(user_id,email)
select id,email from auth.users
where lower(email)=lower('sparkcartmallbd@gmail.com')
on conflict(user_id) do update set email=excluded.email;

drop policy if exists "Admin can read orders" on public.orders;
create policy "Admin can read orders" on public.orders
for select to authenticated using (public.is_sparkcart_admin());

drop policy if exists "Admin can update orders" on public.orders;
create policy "Admin can update orders" on public.orders
for update to authenticated using (public.is_sparkcart_admin()) with check (public.is_sparkcart_admin());

drop policy if exists "Admin can read products" on public.products;
create policy "Admin can read products" on public.products
for select to authenticated using (public.is_sparkcart_admin());

drop policy if exists "Admin can insert products" on public.products;
create policy "Admin can insert products" on public.products
for insert to authenticated with check (public.is_sparkcart_admin());

drop policy if exists "Admin can update products" on public.products;
create policy "Admin can update products" on public.products
for update to authenticated using (public.is_sparkcart_admin()) with check (public.is_sparkcart_admin());

drop policy if exists "Admin can delete products" on public.products;
create policy "Admin can delete products" on public.products
for delete to authenticated using (public.is_sparkcart_admin());

-- SparkCart Mall: 50-product Bangladesh trend catalog (2026-08-20).
-- Re-running this block updates matching products by unique name.
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Smartwatch S9 AMOLED','Smart Accessories',1890,2490,24,4.5,20,'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=700&q=80',20,'হট',true,'কল, নোটিফিকেশন, স্টেপ কাউন্ট ও দৈনন্দিন ফিটনেস ট্র্যাকিংয়ের জন্য স্টাইলিশ স্মার্টওয়াচ। তরুণদের জন্য সহজ গিফট আইডিয়া।','Bluetooth • AMOLED-style display • Activity tracking • Magnetic charging','SC-GAD-001',NULL,'["https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=700&q=80"]','["Black", "Silver"]','[]','Smartwatch S9 AMOLED | SparkCart Mall Bangladesh','কল, নোটিফিকেশন, স্টেপ কাউন্ট ও দৈনন্দিন ফিটনেস ট্র্যাকিংয়ের জন্য স্টাইলিশ স্মার্টওয়াচ। তরুণদের জন্য সহজ গিফট আইডিয়া।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('TWS Earbuds Pro X1','Smart Accessories',1290,1690,24,4.5,20,'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=700&q=80',20,'সেরা বিক্রি',true,'কমপ্যাক্ট TWS ইয়ারবাড—মিউজিক, কল ও দৈনন্দিন ব্যবহারের জন্য উপযোগী।','Bluetooth • Touch control • Charging case • Stereo sound','SC-GAD-002',NULL,'["https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=700&q=80"]','["Black", "White"]','[]','TWS Earbuds Pro X1 | SparkCart Mall Bangladesh','কমপ্যাক্ট TWS ইয়ারবাড—মিউজিক, কল ও দৈনন্দিন ব্যবহারের জন্য উপযোগী।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('FRB N-27 Smart Neckband','Smart Accessories',990,1290,23,4.5,20,'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',true,'মিউজিক, কলিং ও ট্রাভেলের জন্য আরামদায়ক স্মার্ট নেকব্যান্ড।','Bluetooth 5.4 • Neckband design • Voice support • Rechargeable','SC-GAD-003',NULL,'["https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','FRB N-27 Smart Neckband | SparkCart Mall Bangladesh','মিউজিক, কলিং ও ট্রাভেলের জন্য আরামদায়ক স্মার্ট নেকব্যান্ড।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Mini Bluetooth Speaker','Smart Accessories',990,1290,23,4.5,20,'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=700&q=80',20,'হট',false,'ছোট সাইজের পোর্টেবল ব্লুটুথ স্পিকার—রুম, ভ্রমণ ও ছোট গ্যাদারিংয়ের জন্য।','Bluetooth • Portable • Rechargeable battery • Compact body','SC-GAD-004',NULL,'["https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=700&q=80"]','["Black", "Blue"]','[]','Mini Bluetooth Speaker | SparkCart Mall Bangladesh','ছোট সাইজের পোর্টেবল ব্লুটুথ স্পিকার—রুম, ভ্রমণ ও ছোট গ্যাদারিংয়ের জন্য।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Power Bank 10000mAh','Smart Accessories',1090,1390,22,4.5,20,'https://images.unsplash.com/photo-1609592424634-9a9c8c2d6f6b?auto=format&fit=crop&w=700&q=80',20,'অফার',true,'দৈনন্দিন মোবাইল ব্যাকআপের জন্য কমপ্যাক্ট 10000mAh পাওয়ার ব্যাংক।','10000mAh • USB output • LED indicator • Portable','SC-GAD-005',NULL,'["https://images.unsplash.com/photo-1609592424634-9a9c8c2d6f6b?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Power Bank 10000mAh | SparkCart Mall Bangladesh','দৈনন্দিন মোবাইল ব্যাকআপের জন্য কমপ্যাক্ট 10000mAh পাওয়ার ব্যাংক।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Fast Charger 20W Type-C','Mobile Accessories',590,790,25,4.5,20,'https://images.unsplash.com/photo-1587033411391-5d9e51cce126?auto=format&fit=crop&w=700&q=80',20,'হট',true,'Type-C ডিভাইসের জন্য কমপ্যাক্ট ফাস্ট চার্জার। বাসা, অফিস ও ট্রাভেলে ব্যবহারযোগ্য।','20W class • USB-C • Compact adapter • Cable compatible','SC-MOB-001',NULL,'["https://images.unsplash.com/photo-1587033411391-5d9e51cce126?auto=format&fit=crop&w=700&q=80"]','["White"]','[]','Fast Charger 20W Type-C | SparkCart Mall Bangladesh','Type-C ডিভাইসের জন্য কমপ্যাক্ট ফাস্ট চার্জার। বাসা, অফিস ও ট্রাভেলে ব্যবহারযোগ্য।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Type-C Fast Charging Cable 1m','Mobile Accessories',350,450,22,4.5,20,'https://images.unsplash.com/photo-1587033411391-5d9e51cce126?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',false,'চার্জিং ও ডেটা ট্রান্সফারের জন্য দৈনন্দিন Type-C কেবল।','USB-A to USB-C • 1m • Flexible cable','SC-MOB-002',NULL,'["https://images.unsplash.com/photo-1587033411391-5d9e51cce126?auto=format&fit=crop&w=700&q=80"]','["White", "Black"]','[]','Type-C Fast Charging Cable 1m | SparkCart Mall Bangladesh','চার্জিং ও ডেটা ট্রান্সফারের জন্য দৈনন্দিন Type-C কেবল।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Adjustable Mobile Holder','Mobile Accessories',290,390,26,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'অফার',true,'ভিডিও দেখা, অনলাইন ক্লাস ও ডেস্ক ব্যবহারের জন্য অ্যাডজাস্টেবল মোবাইল স্ট্যান্ড।','Adjustable angle • Foldable • Desk use','SC-MOB-003',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Adjustable Mobile Holder | SparkCart Mall Bangladesh','ভিডিও দেখা, অনলাইন ক্লাস ও ডেস্ক ব্যবহারের জন্য অ্যাডজাস্টেবল মোবাইল স্ট্যান্ড।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('RGB Gaming Finger Sleeves','Mobile Accessories',220,320,31,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'নতুন',false,'মোবাইল গেমিংয়ের সময় আঙুলের গ্রিপ ও কন্ট্রোল আরও আরামদায়ক করতে তৈরি ফিঙ্গার স্লিভ।','Stretch fabric • Breathable • Gaming grip','SC-MOB-004',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Black", "Grey"]','[]','RGB Gaming Finger Sleeves | SparkCart Mall Bangladesh','মোবাইল গেমিংয়ের সময় আঙুলের গ্রিপ ও কন্ট্রোল আরও আরামদায়ক করতে তৈরি ফিঙ্গার স্লিভ।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Universal Camera Lens Protector','Mobile Accessories',260,360,28,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'নতুন',false,'স্মার্টফোন ক্যামেরা লেন্সকে দৈনন্দিন স্ক্র্যাচ ও ধুলা থেকে সুরক্ষায় সহায়ক।','Universal style • Transparent • Easy fit','SC-MOB-005',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Clear"]','[]','Universal Camera Lens Protector | SparkCart Mall Bangladesh','স্মার্টফোন ক্যামেরা লেন্সকে দৈনন্দিন স্ক্র্যাচ ও ধুলা থেকে সুরক্ষায় সহায়ক।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Mini Portable Blender','Home & Kitchen',1290,1690,24,4.5,20,'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=700&q=80',20,'হট',true,'স্মুদি, শেক ও ছোট পরিমাণের পানীয় তৈরির জন্য কমপ্যাক্ট পোর্টেবল ব্লেন্ডার।','Rechargeable • Portable cup • USB charging','SC-HOM-001',NULL,'["https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=700&q=80"]','["White", "Pink"]','[]','Mini Portable Blender | SparkCart Mall Bangladesh','স্মুদি, শেক ও ছোট পরিমাণের পানীয় তৈরির জন্য কমপ্যাক্ট পোর্টেবল ব্লেন্ডার।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Electric Lunch Box','Home & Kitchen',1190,1590,25,4.5,20,'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',true,'অফিস, স্কুল বা ভ্রমণে খাবার গরম রাখার জন্য সুবিধাজনক ইলেকট্রিক লাঞ্চ বক্স।','Portable • Electric heating • Food container','SC-HOM-002',NULL,'["https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=700&q=80"]','["Blue", "Green"]','[]','Electric Lunch Box | SparkCart Mall Bangladesh','অফিস, স্কুল বা ভ্রমণে খাবার গরম রাখার জন্য সুবিধাজনক ইলেকট্রিক লাঞ্চ বক্স।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Mini Sewing Machine','Home & Kitchen',1490,1890,21,4.5,20,'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=700&q=80',20,'নতুন',false,'ছোটখাটো সেলাই ও ঘরোয়া DIY কাজের জন্য কমপ্যাক্ট মিনি সেলাই মেশিন।','Mini size • Portable • Home DIY use','SC-HOM-003',NULL,'["https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=700&q=80"]','["White"]','[]','Mini Sewing Machine | SparkCart Mall Bangladesh','ছোটখাটো সেলাই ও ঘরোয়া DIY কাজের জন্য কমপ্যাক্ট মিনি সেলাই মেশিন।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Oil Sprayer Bottle','Home & Kitchen',390,520,25,4.5,20,'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=700&q=80',20,'অফার',true,'রান্না ও সালাদে তেল নিয়ন্ত্রিতভাবে ব্যবহার করার জন্য রিফিলেবল স্প্রে বোতল।','Refillable • Spray nozzle • Kitchen use','SC-HOM-004',NULL,'["https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=700&q=80"]','["Clear"]','[]','Oil Sprayer Bottle | SparkCart Mall Bangladesh','রান্না ও সালাদে তেল নিয়ন্ত্রিতভাবে ব্যবহার করার জন্য রিফিলেবল স্প্রে বোতল।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Kitchen Storage Organizer Set','Home & Kitchen',850,1090,22,4.5,20,'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',true,'মসলা, ছোট রান্নাঘরের জিনিস ও দৈনন্দিন সামগ্রী গুছিয়ে রাখতে মাল্টি-পারপাস অর্গানাইজার সেট।','Stackable • Space saving • Easy clean','SC-HOM-005',NULL,'["https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80"]','["Clear"]','[]','Kitchen Storage Organizer Set | SparkCart Mall Bangladesh','মসলা, ছোট রান্নাঘরের জিনিস ও দৈনন্দিন সামগ্রী গুছিয়ে রাখতে মাল্টি-পারপাস অর্গানাইজার সেট।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Rechargeable Hair Trimmer','Personal Care & Grooming',890,1190,25,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'সেরা বিক্রি',true,'বাড়িতে দ্রুত grooming-এর জন্য রিচার্জেবল হেয়ার ট্রিমার।','Rechargeable • Multiple trim lengths • Compact','SC-GRM-001',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Rechargeable Hair Trimmer | SparkCart Mall Bangladesh','বাড়িতে দ্রুত grooming-এর জন্য রিচার্জেবল হেয়ার ট্রিমার।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Hair Straightener Ceramic','Personal Care & Grooming',990,1290,23,4.5,20,'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=700&q=80',20,'হট',true,'দৈনন্দিন হেয়ার স্টাইলিংয়ের জন্য কমপ্যাক্ট সিরামিক হেয়ার স্ট্রেইটনার।','Ceramic plates • Fast heat-up class • Compact','SC-GRM-002',NULL,'["https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=700&q=80"]','["Black", "Pink"]','[]','Hair Straightener Ceramic | SparkCart Mall Bangladesh','দৈনন্দিন হেয়ার স্টাইলিংয়ের জন্য কমপ্যাক্ট সিরামিক হেয়ার স্ট্রেইটনার।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Hair Curler Styling Tool','Personal Care & Grooming',1090,1390,22,4.5,20,'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=700&q=80',20,'নতুন',false,'বাড়িতে সহজে কার্ল ও স্টাইল করার জন্য কমপ্যাক্ট হেয়ার কার্লার।','Curling barrel • Compact handle • Home styling','SC-GRM-003',NULL,'["https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Hair Curler Styling Tool | SparkCart Mall Bangladesh','বাড়িতে সহজে কার্ল ও স্টাইল করার জন্য কমপ্যাক্ট হেয়ার কার্লার।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Facial Cleansing Brush','Personal Care & Grooming',450,650,31,4.5,20,'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=700&q=80',20,'অফার',false,'স্কিনকেয়ার রুটিনে মৃদু ক্লিনজিংয়ের জন্য সহজে ব্যবহারযোগ্য ফেসিয়াল ক্লিনজিং ব্রাশ।','Soft bristles • Handheld • Easy clean','SC-GRM-004',NULL,'["https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=700&q=80"]','["Pink", "White"]','[]','Facial Cleansing Brush | SparkCart Mall Bangladesh','স্কিনকেয়ার রুটিনে মৃদু ক্লিনজিংয়ের জন্য সহজে ব্যবহারযোগ্য ফেসিয়াল ক্লিনজিং ব্রাশ।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Nose & Detail Trimmer','Personal Care & Grooming',590,790,25,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',false,'দৈনন্দিন personal grooming-এর ছোটখাটো কাজের জন্য কমপ্যাক্ট ট্রিমার।','Compact • Battery powered • Easy grip','SC-GRM-005',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Nose & Detail Trimmer | SparkCart Mall Bangladesh','দৈনন্দিন personal grooming-এর ছোটখাটো কাজের জন্য কমপ্যাক্ট ট্রিমার।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Trendy Women Handbag','Women Fashion & Cosmetics',1290,1690,24,4.5,20,'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',true,'দৈনন্দিন ব্যবহার, অফিস ও ক্যাজুয়াল আউটিংয়ের জন্য স্টাইলিশ women handbag।','Shoulder carry • Multiple compartments • Everyday use','SC-WFC-001',NULL,'["https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=700&q=80"]','["Black", "Brown"]','[]','Trendy Women Handbag | SparkCart Mall Bangladesh','দৈনন্দিন ব্যবহার, অফিস ও ক্যাজুয়াল আউটিংয়ের জন্য স্টাইলিশ women handbag।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Skincare Combo Set','Women Fashion & Cosmetics',990,1290,23,4.5,20,'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=700&q=80',20,'অফার',true,'দৈনন্দিন skincare routine-এর জন্য সাজানো basic skincare combo set।','Combo set • Daily care • Gift friendly','SC-WFC-002',NULL,'["https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=700&q=80"]','["Mixed"]','[]','Skincare Combo Set | SparkCart Mall Bangladesh','দৈনন্দিন skincare routine-এর জন্য সাজানো basic skincare combo set।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Matte Lipstick Set','Women Fashion & Cosmetics',690,890,22,4.5,20,'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=700&q=80',20,'হট',true,'বিভিন্ন লুকের জন্য ব্যবহারযোগ্য কমপ্যাক্ট matte lipstick set।','Matte finish • Multiple shades • Compact','SC-WFC-003',NULL,'["https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=700&q=80"]','["Mixed"]','[]','Matte Lipstick Set | SparkCart Mall Bangladesh','বিভিন্ন লুকের জন্য ব্যবহারযোগ্য কমপ্যাক্ট matte lipstick set।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Jewelry Organizer Box','Women Fashion & Cosmetics',590,790,25,4.5,20,'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80',20,'নতুন',false,'গয়না, রিং ও ছোট accessories গুছিয়ে রাখার জন্য কমপ্যাক্ট organizer box।','Multiple sections • Compact • Travel friendly','SC-WFC-004',NULL,'["https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80"]','["Pink", "Black"]','[]','Jewelry Organizer Box | SparkCart Mall Bangladesh','গয়না, রিং ও ছোট accessories গুছিয়ে রাখার জন্য কমপ্যাক্ট organizer box।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Makeup Brush Set','Women Fashion & Cosmetics',790,990,20,4.5,20,'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',true,'মেকআপ রুটিনে বিভিন্ন ধাপের জন্য প্রয়োজনীয় basic brush set।','Multiple brushes • Soft bristles • Carry case','SC-WFC-005',NULL,'["https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Makeup Brush Set | SparkCart Mall Bangladesh','মেকআপ রুটিনে বিভিন্ন ধাপের জন্য প্রয়োজনীয় basic brush set।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Premium Leather Wallet','Men Fashion & Lifestyle',650,850,24,4.5,20,'https://images.unsplash.com/photo-1627123424574-724758594e93?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',true,'কার্ড, ক্যাশ ও দৈনন্দিন প্রয়োজনীয় জিনিস রাখার জন্য স্লিম leather-look wallet।','Card slots • Cash compartment • Slim profile','SC-MEN-001',NULL,'["https://images.unsplash.com/photo-1627123424574-724758594e93?auto=format&fit=crop&w=700&q=80"]','["Black", "Brown"]','[]','Premium Leather Wallet | SparkCart Mall Bangladesh','কার্ড, ক্যাশ ও দৈনন্দিন প্রয়োজনীয় জিনিস রাখার জন্য স্লিম leather-look wallet।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Classic Leather Belt','Men Fashion & Lifestyle',590,790,25,4.5,20,'https://images.unsplash.com/photo-1627123424574-724758594e93?auto=format&fit=crop&w=700&q=80',20,'অফার',false,'অফিস ও ক্যাজুয়াল পোশাকের সঙ্গে মানানসই ক্লাসিক লুকের বেল্ট।','Adjustable fit • Classic buckle • Everyday wear','SC-MEN-002',NULL,'["https://images.unsplash.com/photo-1627123424574-724758594e93?auto=format&fit=crop&w=700&q=80"]','["Black", "Brown"]','[]','Classic Leather Belt | SparkCart Mall Bangladesh','অফিস ও ক্যাজুয়াল পোশাকের সঙ্গে মানানসই ক্লাসিক লুকের বেল্ট।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Classic UV Sunglasses','Men Fashion & Lifestyle',590,790,25,4.5,20,'https://images.unsplash.com/photo-1511499767150-a48a237f0083?auto=format&fit=crop&w=700&q=80',20,'হট',true,'ক্যাজুয়াল আউটিং ও দৈনন্দিন ব্যবহারের জন্য ক্লাসিক স্টাইলের সানগ্লাস।','Classic frame • UV-style lens • Lightweight','SC-MEN-003',NULL,'["https://images.unsplash.com/photo-1511499767150-a48a237f0083?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Classic UV Sunglasses | SparkCart Mall Bangladesh','ক্যাজুয়াল আউটিং ও দৈনন্দিন ব্যবহারের জন্য ক্লাসিক স্টাইলের সানগ্লাস।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Men Polo T-Shirt','Men Fashion & Lifestyle',750,950,21,4.5,20,'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',true,'ক্যাজুয়াল ও স্মার্ট-ক্যাজুয়াল লুকের জন্য আরামদায়ক polo T-shirt।','Cotton-blend feel • Short sleeve • Casual fit','SC-MEN-004',NULL,'["https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?auto=format&fit=crop&w=700&q=80"]','["Black", "Navy", "White"]','["M", "L", "XL"]','Men Polo T-Shirt | SparkCart Mall Bangladesh','ক্যাজুয়াল ও স্মার্ট-ক্যাজুয়াল লুকের জন্য আরামদায়ক polo T-shirt।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Casual Analog Watch','Men Fashion & Lifestyle',890,1190,25,4.5,20,'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=700&q=80',20,'নতুন',false,'অফিস, ক্যাজুয়াল ও গিফটিংয়ের জন্য মিনিমাল ডিজাইনের analog watch।','Analog dial • Quartz style • Casual strap','SC-MEN-005',NULL,'["https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=700&q=80"]','["Black", "Brown"]','[]','Casual Analog Watch | SparkCart Mall Bangladesh','অফিস, ক্যাজুয়াল ও গিফটিংয়ের জন্য মিনিমাল ডিজাইনের analog watch।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Motion Sensor Night Light','Smart Home & Lighting',490,690,29,4.5,20,'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80',20,'হট',true,'সিঁড়ি, করিডোর, বেডসাইড বা আলমারির জন্য motion-activated night light।','Motion sensor • LED • Compact • Indoor use','SC-LGT-001',NULL,'["https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80"]','["White"]','[]','Motion Sensor Night Light | SparkCart Mall Bangladesh','সিঁড়ি, করিডোর, বেডসাইড বা আলমারির জন্য motion-activated night light।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('RGB LED Strip Light 5m','Smart Home & Lighting',790,990,20,4.5,20,'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',true,'রুম, ডেস্ক ও gaming setup সাজাতে 5m RGB LED strip light।','5m • RGB lighting • Decorative use','SC-LGT-002',NULL,'["https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80"]','["RGB"]','[]','RGB LED Strip Light 5m | SparkCart Mall Bangladesh','রুম, ডেস্ক ও gaming setup সাজাতে 5m RGB LED strip light।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Sunset Projection Lamp','Smart Home & Lighting',690,890,22,4.5,20,'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80',20,'নতুন',true,'রুম ডেকোরেশন ও content setup-এর জন্য sunset-style ambient lamp।','Projection lamp • Adjustable angle • Indoor use','SC-LGT-003',NULL,'["https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80"]','["Orange"]','[]','Sunset Projection Lamp | SparkCart Mall Bangladesh','রুম ডেকোরেশন ও content setup-এর জন্য sunset-style ambient lamp।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Rechargeable Desk Lamp','Smart Home & Lighting',690,890,22,4.5,20,'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80',20,'অফার',true,'পড়াশোনা, অফিস ও bedside use-এর জন্য rechargeable desk lamp।','Rechargeable • Desk size • Adjustable angle','SC-LGT-004',NULL,'["https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80"]','["White", "Black"]','[]','Rechargeable Desk Lamp | SparkCart Mall Bangladesh','পড়াশোনা, অফিস ও bedside use-এর জন্য rechargeable desk lamp।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('USB LED Night Lamp','Smart Home & Lighting',390,550,29,4.5,20,'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',false,'ডেস্ক, bedside বা ছোট workspace-এ soft lighting-এর জন্য USB LED lamp।','USB powered • Compact • Indoor use','SC-LGT-005',NULL,'["https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80"]','["White"]','[]','USB LED Night Lamp | SparkCart Mall Bangladesh','ডেস্ক, bedside বা ছোট workspace-এ soft lighting-এর জন্য USB LED lamp।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('RGB Gaming Mouse','Computer & Gaming Accessories',690,890,22,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'সেরা বিক্রি',true,'PC gaming ও everyday work-এর জন্য RGB lighting সহ ergonomic gaming mouse।','USB • RGB lighting • Ergonomic grip','SC-GAM-001',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','RGB Gaming Mouse | SparkCart Mall Bangladesh','PC gaming ও everyday work-এর জন্য RGB lighting সহ ergonomic gaming mouse।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Mechanical Gaming Keyboard','Computer & Gaming Accessories',1590,1990,20,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'হট',true,'গেমিং ও টাইপিংয়ের জন্য mechanical-style keyboard with RGB lighting।','USB • Mechanical-style switches • RGB','SC-GAM-002',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Mechanical Gaming Keyboard | SparkCart Mall Bangladesh','গেমিং ও টাইপিংয়ের জন্য mechanical-style keyboard with RGB lighting।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Large RGB Gaming Mousepad','Computer & Gaming Accessories',790,990,20,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',false,'মাউসের smooth movement ও gaming desk setup-এর জন্য বড় RGB mousepad।','Large surface • RGB edge • Non-slip base','SC-GAM-003',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Large RGB Gaming Mousepad | SparkCart Mall Bangladesh','মাউসের smooth movement ও gaming desk setup-এর জন্য বড় RGB mousepad।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Headphone Stand','Computer & Gaming Accessories',590,790,25,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'নতুন',false,'ডেস্ক গুছিয়ে রাখতে headphone ও gaming headset রাখার স্ট্যান্ড।','Desk stand • Space saving • Stable base','SC-GAM-004',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Headphone Stand | SparkCart Mall Bangladesh','ডেস্ক গুছিয়ে রাখতে headphone ও gaming headset রাখার স্ট্যান্ড।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Laptop Cooling Pad','Computer & Gaming Accessories',990,1290,23,4.5,20,'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80',20,'অফার',true,'ল্যাপটপের নিচে airflow বাড়াতে সহায়ক cooling pad—gaming ও heavy use-এর জন্য।','USB powered • Fan cooling • Laptop compatible','SC-GAM-005',NULL,'["https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Laptop Cooling Pad | SparkCart Mall Bangladesh','ল্যাপটপের নিচে airflow বাড়াতে সহায়ক cooling pad—gaming ও heavy use-এর জন্য।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Bike Mobile Holder','Car & Bike Accessories',650,850,24,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'সেরা বিক্রি',true,'বাইকে navigation ও প্রয়োজনীয় ফোন viewing-এর জন্য handlebar mobile holder।','Handlebar mount • Adjustable grip • Phone compatible','SC-AUTO-001',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Bike Mobile Holder | SparkCart Mall Bangladesh','বাইকে navigation ও প্রয়োজনীয় ফোন viewing-এর জন্য handlebar mobile holder।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Helmet Bluetooth Intercom','Car & Bike Accessories',1490,1890,21,4.5,20,'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=700&q=80',20,'হট',true,'রাইডের সময় compatible helmet-এ Bluetooth calling ও audio-এর জন্য intercom device।','Bluetooth • Helmet compatible • Rechargeable','SC-AUTO-002',NULL,'["https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Helmet Bluetooth Intercom | SparkCart Mall Bangladesh','রাইডের সময় compatible helmet-এ Bluetooth calling ও audio-এর জন্য intercom device।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Car Cleaning Duster','Car & Bike Accessories',350,490,29,4.5,20,'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80',20,'অফার',false,'গাড়ির dashboard ও interior-এর ধুলো পরিষ্কারে ব্যবহারযোগ্য soft cleaning duster।','Soft microfiber • Reusable • Interior cleaning','SC-AUTO-003',NULL,'["https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80"]','["Grey"]','[]','Car Cleaning Duster | SparkCart Mall Bangladesh','গাড়ির dashboard ও interior-এর ধুলো পরিষ্কারে ব্যবহারযোগ্য soft cleaning duster।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Anti-Glare Side Mirror Pair','Car & Bike Accessories',790,990,20,4.5,20,'https://images.unsplash.com/photo-1511499767150-a48a237f0083?auto=format&fit=crop&w=700&q=80',20,'নতুন',false,'রাইডিংয়ের সময় glare কমাতে সহায়ক anti-glare style side mirror pair।','Pair set • Wide-view style • Universal fit class','SC-AUTO-004',NULL,'["https://images.unsplash.com/photo-1511499767150-a48a237f0083?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Anti-Glare Side Mirror Pair | SparkCart Mall Bangladesh','রাইডিংয়ের সময় glare কমাতে সহায়ক anti-glare style side mirror pair।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Car/Bike Mini Air Pump','Car & Bike Accessories',1190,1490,20,4.5,20,'https://images.unsplash.com/photo-1609592424634-9a9c8c2d6f6b?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',true,'জরুরি সময়ে টায়ারে বাতাস দেওয়ার জন্য portable mini air pump।','Portable • Digital-style display • USB/12V class','SC-AUTO-005',NULL,'["https://images.unsplash.com/photo-1609592424634-9a9c8c2d6f6b?auto=format&fit=crop&w=700&q=80"]','["Black"]','[]','Car/Bike Mini Air Pump | SparkCart Mall Bangladesh','জরুরি সময়ে টায়ারে বাতাস দেওয়ার জন্য portable mini air pump।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Educational Learning Toy Set','Kids & Baby Products',790,990,20,4.5,20,'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80',20,'জনপ্রিয়',true,'শিশুর basic learning, matching ও hand-eye coordination practice-এর জন্য educational toy set।','Learning set • Child-friendly design • Home activity','SC-KID-001',NULL,'["https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80"]','["Mixed"]','[]','Educational Learning Toy Set | SparkCart Mall Bangladesh','শিশুর basic learning, matching ও hand-eye coordination practice-এর জন্য educational toy set।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('LCD Writing Tablet 8.5-inch','Kids & Baby Products',490,690,29,4.5,20,'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80',20,'সেরা বিক্রি',true,'শিশুর drawing, writing ও practice-এর জন্য reusable LCD writing tablet।','8.5-inch class • Reusable screen • Button erase','SC-KID-002',NULL,'["https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=700&q=80"]','["Black", "Pink", "Blue"]','[]','LCD Writing Tablet 8.5-inch | SparkCart Mall Bangladesh','শিশুর drawing, writing ও practice-এর জন্য reusable LCD writing tablet।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Baby Care Kit','Kids & Baby Products',890,1190,25,4.5,20,'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80',20,'অফার',false,'শিশুর দৈনন্দিন care routine-এর জন্য basic baby care accessories kit।','Multi-item kit • Portable pouch • Everyday use','SC-KID-003',NULL,'["https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80"]','["Mixed"]','[]','Baby Care Kit | SparkCart Mall Bangladesh','শিশুর দৈনন্দিন care routine-এর জন্য basic baby care accessories kit।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Smart Learning Board Book Set','Kids & Baby Products',690,890,22,4.5,20,'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80',20,'নতুন',true,'অক্ষর, সংখ্যা ও basic concepts শেখাতে activity-based board book set।','Board pages • Learning activities • Gift friendly','SC-KID-004',NULL,'["https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=700&q=80"]','["Mixed"]','[]','Smart Learning Board Book Set | SparkCart Mall Bangladesh','অক্ষর, সংখ্যা ও basic concepts শেখাতে activity-based board book set।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();
insert into public.products (name,category,price,old_price,discount,rating,reviews,image,stock,badge,featured,details,specifications,sku,video_url,images,colors,sizes,seo_title,meta_description) values ('Kids Musical Activity Toy','Kids & Baby Products',850,1090,22,4.5,20,'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=700&q=80',20,'হট',false,'শিশুর sensory play ও simple musical activity-এর জন্য colourful activity toy।','Musical activity • Child-friendly • Indoor play','SC-KID-005',NULL,'["https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=700&q=80"]','["Mixed"]','[]','Kids Musical Activity Toy | SparkCart Mall Bangladesh','শিশুর sensory play ও simple musical activity-এর জন্য colourful activity toy।') on conflict(name) do update set category=excluded.category,price=excluded.price,old_price=excluded.old_price,discount=excluded.discount,rating=excluded.rating,reviews=excluded.reviews,image=excluded.image,stock=excluded.stock,badge=excluded.badge,featured=excluded.featured,active=true,details=excluded.details,specifications=excluded.specifications,sku=excluded.sku,images=excluded.images,colors=excluded.colors,sizes=excluded.sizes,seo_title=excluded.seo_title,meta_description=excluded.meta_description,updated_at=now();

-- Public image bucket; only admins may upload/change/delete images.
insert into storage.buckets(id,name,public)
values ('product-images','product-images',true)
on conflict(id) do update set public=true;

drop policy if exists "Public can view product images" on storage.objects;
create policy "Public can view product images" on storage.objects
for select to anon, authenticated using (bucket_id='product-images');

drop policy if exists "Admins upload product images" on storage.objects;
create policy "Admins upload product images" on storage.objects
for insert to authenticated with check (bucket_id='product-images' and public.is_sparkcart_admin());

drop policy if exists "Admins update product images" on storage.objects;
create policy "Admins update product images" on storage.objects
for update to authenticated using (bucket_id='product-images' and public.is_sparkcart_admin())
with check (bucket_id='product-images' and public.is_sparkcart_admin());

drop policy if exists "Admins delete product images" on storage.objects;
create policy "Admins delete product images" on storage.objects
for delete to authenticated using (bucket_id='product-images' and public.is_sparkcart_admin());

-- IMPORTANT: keep service_role/secret keys out of frontend code.

-- Step 2 shopping features: reviews
create table if not exists public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  customer_name text not null check (char_length(customer_name) between 2 and 80),
  rating integer not null check (rating between 1 and 5),
  review_text text not null check (char_length(review_text) between 3 and 1000),
  approved boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists product_reviews_product_idx on public.product_reviews(product_id, created_at desc);
alter table public.product_reviews enable row level security;

drop policy if exists "Public can read approved reviews" on public.product_reviews;
create policy "Public can read approved reviews" on public.product_reviews
for select to anon, authenticated using (approved=true);

drop policy if exists "Public can submit reviews" on public.product_reviews;
create policy "Public can submit reviews" on public.product_reviews
for insert to anon, authenticated with check (approved=false);

drop policy if exists "Admin can read all reviews" on public.product_reviews;
create policy "Admin can read all reviews" on public.product_reviews
for select to authenticated using (public.is_sparkcart_admin());

drop policy if exists "Admin can update reviews" on public.product_reviews;
create policy "Admin can update reviews" on public.product_reviews
for update to authenticated using (public.is_sparkcart_admin()) with check (public.is_sparkcart_admin());

drop policy if exists "Admin can delete reviews" on public.product_reviews;
create policy "Admin can delete reviews" on public.product_reviews
for delete to authenticated using (public.is_sparkcart_admin());

create index if not exists products_category_idx on public.products(category);
create index if not exists products_featured_idx on public.products(featured, active);
create index if not exists products_price_idx on public.products(price);



-- Step 4: Marketing / Coupon system
alter table public.orders add column if not exists coupon_code text;
alter table public.orders add column if not exists discount_amount numeric(12,2) not null default 0 check (discount_amount >= 0);

create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  type text not null default 'fixed' check (type in ('fixed','percent')),
  value numeric(12,2) not null check (value > 0),
  min_order numeric(12,2) not null default 0 check (min_order >= 0),
  max_discount numeric(12,2),
  usage_limit integer,
  used_count integer not null default 0 check (used_count >= 0),
  active boolean not null default true,
  starts_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create unique index if not exists coupons_code_lower_idx on public.coupons(lower(code));
alter table public.coupons enable row level security;

drop policy if exists "Admin can read coupons" on public.coupons;
create policy "Admin can read coupons" on public.coupons
for select to authenticated using (public.is_sparkcart_admin());

drop policy if exists "Admin can insert coupons" on public.coupons;
create policy "Admin can insert coupons" on public.coupons
for insert to authenticated with check (public.is_sparkcart_admin());

drop policy if exists "Admin can update coupons" on public.coupons;
create policy "Admin can update coupons" on public.coupons
for update to authenticated using (public.is_sparkcart_admin()) with check (public.is_sparkcart_admin());

drop policy if exists "Admin can delete coupons" on public.coupons;
create policy "Admin can delete coupons" on public.coupons
for delete to authenticated using (public.is_sparkcart_admin());

create or replace function public.get_coupon_discount(p_code text, p_subtotal numeric)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare c coupons%rowtype; d numeric := 0;
begin
  select * into c from coupons where upper(code)=upper(trim(p_code)) limit 1;
  if not found then return jsonb_build_object('valid',false,'message','Coupon not found'); end if;
  if not c.active then return jsonb_build_object('valid',false,'message','Coupon is inactive'); end if;
  if c.starts_at is not null and now() < c.starts_at then return jsonb_build_object('valid',false,'message','Coupon is not active yet'); end if;
  if c.expires_at is not null and now() > c.expires_at then return jsonb_build_object('valid',false,'message','Coupon expired'); end if;
  if c.usage_limit is not null and c.used_count >= c.usage_limit then return jsonb_build_object('valid',false,'message','Coupon usage limit reached'); end if;
  if coalesce(p_subtotal,0) < c.min_order then return jsonb_build_object('valid',false,'message','Minimum order is ৳'||c.min_order); end if;
  if c.type='percent' then d := coalesce(p_subtotal,0)*c.value/100; if c.max_discount is not null then d:=least(d,c.max_discount); end if;
  else d:=c.value; end if;
  d:=least(greatest(d,0),coalesce(p_subtotal,0));
  return jsonb_build_object('valid',true,'code',upper(c.code),'discount',round(d,2),'type',c.type,'value',c.value);
end $$;
grant execute on function public.get_coupon_discount(text,numeric) to anon, authenticated;

create or replace function public.redeem_coupon(p_code text)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare changed integer;
begin
  update coupons
  set used_count=used_count+1
  where upper(code)=upper(trim(p_code))
    and active=true
    and (starts_at is null or now() >= starts_at)
    and (expires_at is null or now() <= expires_at)
    and (usage_limit is null or used_count < usage_limit);
  get diagnostics changed = row_count;
  return changed=1;
end $$;
grant execute on function public.redeem_coupon(text) to anon, authenticated;


-- STEP 4 SPIN CONTROL
-- Admin controls how many spins a customer can use and the maximum reward.
create table if not exists public.spin_settings (
  id integer primary key default 1 check (id = 1),
  enabled boolean not null default true,
  spins_per_customer integer not null default 1 check (spins_per_customer >= 0 and spins_per_customer <= 50),
  max_discount numeric(12,2) not null default 200 check (max_discount >= 0),
  min_order numeric(12,2) not null default 0 check (min_order >= 0),
  rewards jsonb not null default '[0,50,100,150,200]'::jsonb,
  updated_at timestamptz not null default now()
);

insert into public.spin_settings(id,enabled,spins_per_customer,max_discount,min_order,rewards)
values (1,true,1,200,0,'[0,50,100,150,200]'::jsonb)
on conflict (id) do nothing;

alter table public.spin_settings enable row level security;

drop policy if exists "Public can read spin settings" on public.spin_settings;
create policy "Public can read spin settings" on public.spin_settings
for select to anon, authenticated using (true);

drop policy if exists "Admin can update spin settings" on public.spin_settings;
create policy "Admin can update spin settings" on public.spin_settings
for update to authenticated
using (public.is_sparkcart_admin())
with check (public.is_sparkcart_admin());

drop policy if exists "Admin can insert spin settings" on public.spin_settings;
create policy "Admin can insert spin settings" on public.spin_settings
for insert to authenticated
with check (public.is_sparkcart_admin());



-- =========================
-- SparkCart Feature Upgrade: Payment Details + Customer Tracking
-- SAFE MIGRATION: no DROP/DELETE operations
-- =========================
alter table public.orders add column if not exists payment_number text;
alter table public.orders add column if not exists payment_transaction_id text;
alter table public.orders add column if not exists payment_amount numeric(12,2);
alter table public.orders add column if not exists payment_time timestamptz;

-- Recreate public order insert policy so Rocket is also supported.
drop policy if exists "Public can insert orders" on public.orders;
create policy "Public can insert orders" on public.orders
for insert to anon
with check (
  status='pending'
  and payment_method in ('Cash on Delivery','bKash','Nagad','Rocket')
  and customer_phone ~ '^01[0-9]{9}$'
  and (payment_method='Cash on Delivery' or (payment_number is not null and payment_amount is not null and payment_time is not null))
);

-- Customer tracking RPC: exact Order ID + phone only; exposes limited tracking fields.
create or replace function public.track_order(p_order_id text, p_customer_phone text)
returns table(order_id text, customer_name text, district text, upazila text, total_amount numeric, status text, created_at timestamptz)
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

-- Optional payment method validation helper for future admin/reporting use.
create index if not exists orders_payment_method_idx on public.orders(payment_method);
create index if not exists orders_payment_time_idx on public.orders(payment_time desc);


-- Merchant payment numbers (admin-configurable; blank until admin sets them)
create table if not exists public.payment_settings (
  id integer primary key check (id=1),
  bkash_number text default '',
  nagad_number text default '',
  rocket_number text default '',
  updated_at timestamptz not null default now()
);
insert into public.payment_settings(id) values (1) on conflict(id) do nothing;
alter table public.payment_settings enable row level security;
drop policy if exists "Public can read payment settings" on public.payment_settings;
create policy "Public can read payment settings" on public.payment_settings
for select to anon, authenticated using (id=1);
drop policy if exists "Admin can update payment settings" on public.payment_settings;
create policy "Admin can update payment settings" on public.payment_settings
for update to authenticated using (public.is_sparkcart_admin()) with check (public.is_sparkcart_admin());


-- FlowGet: admin-controlled brand/logo/site text settings
create table if not exists public.site_settings (
  id integer primary key check (id=1),
  brand_name text not null default 'FlowGet',
  site_title text not null default 'FlowGet',
  topbar_text text default '',
  hero_badge text default '🔥 FLASH SALE',
  hero_title text default 'প্রতিদিনের প্রয়োজনীয় পণ্য, এক জায়গায়',
  hero_subtitle text default 'বিশেষ অফার, দ্রুত ডেলিভারি ও সহজ COD checkout — FlowGet-এ।',
  hero_button text default 'অফার দেখুন',
  seller_title text default '🏪 আপনার ব্যবসা অনলাইনে নিন',
  seller_text text default 'FlowGet-এ seller হিসেবে আবেদন করুন এবং approved হলে product sell করুন।',
  whatsapp_number text default '01822024595',
  contact_email text default 'flowget.org@gmail.com',
  footer_text text default 'স্মার্ট পণ্য, সহজ কেনাকাটা।',
  logo_url text default 'assets/brand/flowget-logo.svg',
  updated_at timestamptz not null default now()
);
insert into public.site_settings(id) values (1) on conflict(id) do nothing;
alter table public.site_settings enable row level security;
drop policy if exists "Public can read site settings" on public.site_settings;
create policy "Public can read site settings" on public.site_settings for select to anon, authenticated using (id=1);
drop policy if exists "Admin can update site settings" on public.site_settings;
create policy "Admin can update site settings" on public.site_settings for update to authenticated using (public.is_sparkcart_admin()) with check (public.is_sparkcart_admin());

insert into storage.buckets (id,name,public) values ('site-assets','site-assets',true) on conflict (id) do nothing;
drop policy if exists "Public can view site assets" on storage.objects;
create policy "Public can view site assets" on storage.objects for select to anon, authenticated using (bucket_id='site-assets');
drop policy if exists "Admins upload site assets" on storage.objects;
create policy "Admins upload site assets" on storage.objects for insert to authenticated with check (bucket_id='site-assets' and public.is_sparkcart_admin());
drop policy if exists "Admins update site assets" on storage.objects;
create policy "Admins update site assets" on storage.objects for update to authenticated using (bucket_id='site-assets' and public.is_sparkcart_admin()) with check (bucket_id='site-assets' and public.is_sparkcart_admin());
drop policy if exists "Admins delete site assets" on storage.objects;
create policy "Admins delete site assets" on storage.objects for delete to authenticated using (bucket_id='site-assets' and public.is_sparkcart_admin());

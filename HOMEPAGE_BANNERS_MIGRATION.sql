-- FlowGet: Homepage Banner / Slider Management
-- Additive migration only. Does NOT delete or modify existing products/orders/data.

create table if not exists public.homepage_banners (
  id uuid primary key default gen_random_uuid(),
  badge text not null default '',
  title text not null,
  subtitle text not null default '',
  button_text text not null default 'এখনই দেখুন',
  button_link text not null default '#shop',
  image_url text,
  sort_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists homepage_banners_active_sort_idx
  on public.homepage_banners(active, sort_order, created_at);

alter table public.homepage_banners enable row level security;

-- Public customers may only read active banners.
drop policy if exists "Public can view active homepage banners" on public.homepage_banners;
create policy "Public can view active homepage banners"
on public.homepage_banners
for select to anon, authenticated
using (active = true);

-- Admin can manage all banners.
drop policy if exists "Admins can view all homepage banners" on public.homepage_banners;
create policy "Admins can view all homepage banners"
on public.homepage_banners
for select to authenticated
using (public.is_flowget_admin());

drop policy if exists "Admins can insert homepage banners" on public.homepage_banners;
create policy "Admins can insert homepage banners"
on public.homepage_banners
for insert to authenticated
with check (public.is_flowget_admin());

drop policy if exists "Admins can update homepage banners" on public.homepage_banners;
create policy "Admins can update homepage banners"
on public.homepage_banners
for update to authenticated
using (public.is_flowget_admin())
with check (public.is_flowget_admin());

drop policy if exists "Admins can delete homepage banners" on public.homepage_banners;
create policy "Admins can delete homepage banners"
on public.homepage_banners
for delete to authenticated
using (public.is_flowget_admin());

-- Seed only when the new table is empty. Existing project data is untouched.
insert into public.homepage_banners
  (badge, title, subtitle, button_text, button_link, image_url, sort_order, active)
select * from (values
  ('🔥 FLASH SALE', 'প্রতিদিনের প্রয়োজনীয় পণ্য, এক জায়গায়', 'বিশেষ অফার, দ্রুত ডেলিভারি ও সহজ COD checkout — FlowGet-এ।', 'অফার দেখুন', '#flashSale', null, 1, true),
  ('🚚 Nationwide Delivery', 'সারা বাংলাদেশে ডেলিভারি', 'আপনার পছন্দের পণ্য অর্ডার করুন, অর্ডার স্ট্যাটাসও অনলাইনে ট্র্যাক করুন।', 'শপিং শুরু করুন', '#shop', null, 2, true),
  ('🏪 SELL ON FLOWGET', 'আপনিও Seller হোন', 'আপনার পণ্য FlowGet-এ বিক্রি করার জন্য seller application পাঠান।', 'Become a Seller', '#seller', null, 3, true)
) as seed(badge,title,subtitle,button_text,button_link,image_url,sort_order,active)
where not exists (select 1 from public.homepage_banners);

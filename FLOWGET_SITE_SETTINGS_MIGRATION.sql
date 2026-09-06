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

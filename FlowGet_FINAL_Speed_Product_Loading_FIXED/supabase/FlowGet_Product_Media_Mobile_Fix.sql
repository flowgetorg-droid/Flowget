-- FlowGet: mobile product media + main image editing migration
-- Run once in Supabase SQL Editor.

create extension if not exists pgcrypto;

alter table if exists public.products add column if not exists video_url text;

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  url text not null,
  sort_order int default 0,
  created_at timestamptz default now()
);

-- Storage bucket for product images/videos.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values (
  'product-media','product-media',true,52428800,
  array['image/jpeg','image/png','image/webp','image/gif','image/avif','video/mp4','video/webm','video/quicktime']::text[]
)
on conflict (id) do update set
  public=true,
  file_size_limit=52428800,
  allowed_mime_types=excluded.allowed_mime_types;

-- Recreate only FlowGet product-media policies.
drop policy if exists "FlowGet product media public read" on storage.objects;
drop policy if exists "FlowGet product media admin insert" on storage.objects;
drop policy if exists "FlowGet product media admin update" on storage.objects;
drop policy if exists "FlowGet product media admin delete" on storage.objects;

create policy "FlowGet product media public read"
on storage.objects for select
using (bucket_id='product-media');

create policy "FlowGet product media admin insert"
on storage.objects for insert to authenticated
with check (
  bucket_id='product-media'
  and exists (select 1 from public.admin_users a where a.user_id=auth.uid())
);

create policy "FlowGet product media admin update"
on storage.objects for update to authenticated
using (
  bucket_id='product-media'
  and exists (select 1 from public.admin_users a where a.user_id=auth.uid())
)
with check (
  bucket_id='product-media'
  and exists (select 1 from public.admin_users a where a.user_id=auth.uid())
);

create policy "FlowGet product media admin delete"
on storage.objects for delete to authenticated
using (
  bucket_id='product-media'
  and exists (select 1 from public.admin_users a where a.user_id=auth.uid())
);

-- Gallery read/write policies.
drop policy if exists "FlowGet product images public read" on public.product_images;
drop policy if exists "FlowGet product images admin all" on public.product_images;

create policy "FlowGet product images public read"
on public.product_images for select
using (
  exists (
    select 1 from public.products p
    where p.id=product_images.product_id and p.active=true
  )
);

create policy "FlowGet product images admin all"
on public.product_images for all to authenticated
using (
  exists (select 1 from public.admin_users a where a.user_id=auth.uid())
)
with check (
  exists (select 1 from public.admin_users a where a.user_id=auth.uid())
);

notify pgrst, 'reload schema';

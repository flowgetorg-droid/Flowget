-- FlowGet product schema compatibility migration
-- Safe for an existing database: additive only. Never drops/truncates/deletes data.
-- Run once in Supabase SQL Editor, then refresh the admin page.

alter table if exists public.products
  add column if not exists name text,
  add column if not exists slug text,
  add column if not exists description text,
  add column if not exists short_description text,
  add column if not exists specifications jsonb default '{}'::jsonb,
  add column if not exists category_id uuid,
  add column if not exists brand text,
  add column if not exists sku text,
  add column if not exists price numeric default 0,
  add column if not exists discount_price numeric,
  add column if not exists stock integer default 0,
  add column if not exists main_image text,
  add column if not exists video_url text,
  add column if not exists active boolean default true,
  add column if not exists rating numeric default 0,
  add column if not exists review_count integer default 0,
  add column if not exists featured boolean default false,
  add column if not exists new_arrival boolean default false,
  add column if not exists flash_deal boolean default false,
  add column if not exists is_best_selling boolean default false,
  add column if not exists seo_title text,
  add column if not exists meta_description text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  url text not null,
  sort_order integer default 0,
  created_at timestamptz default now()
);

select pg_notify('pgrst', 'reload schema');

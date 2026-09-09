-- FlowGet Product/Admin compatibility migration
-- SAFE: adds missing product columns only; does not drop/truncate/delete existing data.

alter table if exists public.products
  add column if not exists slug text,
  add column if not exists description text,
  add column if not exists sku text,
  add column if not exists brand text,
  add column if not exists category_id uuid,
  add column if not exists price numeric,
  add column if not exists discount_price numeric,
  add column if not exists stock integer default 0,
  add column if not exists main_image text,
  add column if not exists video_url text,
  add column if not exists specifications jsonb default '{}'::jsonb,
  add column if not exists active boolean default true,
  add column if not exists rating numeric default 0,
  add column if not exists review_count integer default 0,
  add column if not exists meta_description text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

-- If an older schema has a text/category column, preserve it by mapping matching
-- category names/slugs into the modern category_id field when possible.
do $$
begin
  if to_regclass('public.categories') is not null
     and exists (select 1 from information_schema.columns where table_schema='public' and table_name='products' and column_name='category') then
    update public.products p
       set category_id = c.id
      from public.categories c
     where p.category_id is null
       and (
         lower(trim(coalesce(p.category,''))) = lower(trim(coalesce(c.name,'')))
         or lower(trim(coalesce(p.category,''))) = lower(trim(coalesce(c.slug,'')))
       );
  end if;
end $$;

-- Keep timestamps current for existing/new product edits when the trigger exists.
do $$
begin
  if to_regclass('public.products') is not null then
    create index if not exists products_slug_lower_idx on public.products (lower(slug));
    create index if not exists products_sku_lower_idx on public.products (lower(sku));
  end if;
end $$;

-- Ensure the gallery table exists for the current Admin/Product UI.
create extension if not exists pgcrypto;
create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  url text not null,
  sort_order integer default 0,
  created_at timestamptz default now()
);

notify pgrst, 'reload schema';

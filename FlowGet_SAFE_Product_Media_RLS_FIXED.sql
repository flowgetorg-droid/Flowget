-- FlowGet SAFE Product Media + RLS (Syntax corrected)
-- Preserves existing policies and all product/order/review data.
-- Does not insert demo products/categories or delete gallery rows.

begin;

-- Required schema checks
do $$
begin
  if to_regclass('public.admin_users') is null then
    raise exception 'Required table public.admin_users was not found.';
  end if;
  if to_regclass('public.products') is null then
    raise exception 'Required table public.products was not found.';
  end if;
  if to_regclass('public.product_images') is null then
    raise exception 'Required table public.product_images was not found.';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='admin_users' and column_name='user_id'
  ) then
    raise exception 'public.admin_users.user_id was not found.';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='product_images' and column_name='product_id'
  ) then
    raise exception 'public.product_images.product_id was not found.';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='products' and column_name='active'
  ) then
    raise exception 'public.products.active was not found.';
  end if;
end
$$;

-- Create bucket if missing. Do not overwrite existing bucket configuration.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-media',
  'product-media',
  true,
  52428800,
  array[
    'image/jpeg','image/png','image/webp','image/gif',
    'video/mp4','video/webm','video/quicktime'
  ]::text[]
)
on conflict (id) do nothing;

-- Ensure customer browsers can load public product-media URLs.
update storage.buckets
set public = true
where id = 'product-media';

-- Add uniquely named storage policies only if they do not already exist.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='flowget_product_media_public_read_safe'
  ) then
    execute $policy$
      create policy flowget_product_media_public_read_safe
      on storage.objects for select
      using (bucket_id = 'product-media')
    $policy$;
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='flowget_product_media_admin_insert_safe'
  ) then
    execute $policy$
      create policy flowget_product_media_admin_insert_safe
      on storage.objects for insert to authenticated
      with check (
        bucket_id = 'product-media'
        and exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      )
    $policy$;
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='flowget_product_media_admin_update_safe'
  ) then
    execute $policy$
      create policy flowget_product_media_admin_update_safe
      on storage.objects for update to authenticated
      using (
        bucket_id = 'product-media'
        and exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      )
      with check (
        bucket_id = 'product-media'
        and exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      )
    $policy$;
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='flowget_product_media_admin_delete_safe'
  ) then
    execute $policy$
      create policy flowget_product_media_admin_delete_safe
      on storage.objects for delete to authenticated
      using (
        bucket_id = 'product-media'
        and exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      )
    $policy$;
  end if;
end
$$;

-- Enable RLS on gallery table; preserve every existing policy.
alter table public.product_images enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='product_images'
      and policyname='flowget_product_images_active_read_safe'
  ) then
    execute $policy$
      create policy flowget_product_images_active_read_safe
      on public.product_images for select
      using (
        exists (
          select 1 from public.products p
          where p.id = product_images.product_id
            and p.active = true
        )
      )
    $policy$;
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='product_images'
      and policyname='flowget_product_images_admin_manage_safe'
  ) then
    execute $policy$
      create policy flowget_product_images_admin_manage_safe
      on public.product_images for all to authenticated
      using (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      )
      with check (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      )
    $policy$;
  end if;
end
$$;

commit;

-- Verify that the policies from this script exist.
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where (schemaname='storage' and tablename='objects'
       and policyname like 'flowget_product_media_%_safe')
   or (schemaname='public' and tablename='product_images'
       and policyname like 'flowget_product_images_%_safe')
order by schemaname, tablename, policyname;

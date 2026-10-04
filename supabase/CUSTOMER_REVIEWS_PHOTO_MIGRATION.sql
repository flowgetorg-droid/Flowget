-- FlowGet Customer Review + Photo Migration
-- Run this ONCE in Supabase SQL Editor on an existing FlowGet database.
-- Safe/additive: it does not delete products, orders, customers, or existing reviews.

alter table public.reviews add column if not exists photo_url text;

-- Public customers may submit only unapproved reviews for active products.
drop policy if exists "public reviews insert" on public.reviews;
create policy "public reviews insert"
on public.reviews for insert
to anon, authenticated
with check(
  approved=false
  and rating between 1 and 5
  and char_length(trim(coalesce(customer_name,''))) between 2 and 80
  and char_length(trim(coalesce(review_text,''))) between 5 and 1000
  and exists(
    select 1 from public.products p
    where p.id=reviews.product_id and p.active=true
  )
);

-- Review photo storage. Customer uploads are limited by the app to image files <=5MB.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('review-media','review-media',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;

drop policy if exists "public review media read" on storage.objects;
create policy "public review media read"
on storage.objects for select
using(bucket_id='review-media');

drop policy if exists "public review media insert" on storage.objects;
create policy "public review media insert"
on storage.objects for insert
to anon, authenticated
with check(
  bucket_id='review-media'
  and (storage.foldername(name))[1]='reviews'
);

drop policy if exists "admin review media delete" on storage.objects;
create policy "admin review media delete"
on storage.objects for delete to authenticated
using(bucket_id='review-media' and public.is_admin());

-- Keep product rating/review_count in sync with approved reviews.
create or replace function public.refresh_product_review_stats()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  pid uuid;
begin
  if tg_op <> 'INSERT' and old.product_id is not null then
    pid := old.product_id;
    update public.products p
    set rating=coalesce((select round(avg(r.rating)::numeric,1) from public.reviews r where r.product_id=pid and r.approved=true),0),
        review_count=(select count(*) from public.reviews r where r.product_id=pid and r.approved=true)
    where p.id=pid;
  end if;
  if tg_op <> 'DELETE' and new.product_id is not null then
    pid := new.product_id;
    update public.products p
    set rating=coalesce((select round(avg(r.rating)::numeric,1) from public.reviews r where r.product_id=pid and r.approved=true),0),
        review_count=(select count(*) from public.reviews r where r.product_id=pid and r.approved=true)
    where p.id=pid;
  end if;
  return coalesce(new,old);
end;
$$;

drop trigger if exists reviews_refresh_product_stats on public.reviews;
create trigger reviews_refresh_product_stats
after insert or update of product_id,rating,approved or delete on public.reviews
for each row execute function public.refresh_product_review_stats();

update public.products p
set rating=coalesce((select round(avg(r.rating)::numeric,1) from public.reviews r where r.product_id=p.id and r.approved=true),0),
    review_count=(select count(*) from public.reviews r where r.product_id=p.id and r.approved=true);

-- No service-role key is needed.

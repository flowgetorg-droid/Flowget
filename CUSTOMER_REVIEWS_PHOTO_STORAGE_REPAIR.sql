-- FlowGet Customer Review Photo Storage Repair
-- Run this once to configure normal Supabase Storage uploads for customer review photos.
-- The app also has a compressed-photo fallback if the browser cannot reach Storage.
-- Safe/additive: does not delete products, orders, customers, or reviews.

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('review-media','review-media',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set
  public=true,
  file_size_limit=5242880,
  allowed_mime_types=array['image/jpeg','image/png','image/webp'];

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

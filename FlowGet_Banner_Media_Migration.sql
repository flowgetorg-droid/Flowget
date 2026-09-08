-- FlowGet: Banner image upload support
-- Run this once in Supabase SQL Editor before deploying the ZIP.

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

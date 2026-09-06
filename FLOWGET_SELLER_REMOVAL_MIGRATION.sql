-- FlowGet: remove seller workflow safely.
-- Safe if the seller tables do not exist. Does not touch products, orders or customers.
drop table if exists public.sellers cascade;
drop table if exists public.seller_applications cascade;

-- Remove any old seller CTA banners only if homepage_banners exists.
do $$
begin
  if to_regclass('public.homepage_banners') is not null then
    delete from public.homepage_banners
    where button_link = '#seller'
       or lower(coalesce(badge,'')) like '%sell on sparkcart%'
       or lower(coalesce(title,'')) like '%seller%';
  end if;
end $$;

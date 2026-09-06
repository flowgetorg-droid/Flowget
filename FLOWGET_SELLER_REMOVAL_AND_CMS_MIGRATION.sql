-- FlowGet: remove seller feature and enable generic text overrides
alter table public.site_settings add column if not exists custom_texts jsonb not null default '{}'::jsonb;
alter table public.site_settings drop column if exists seller_title;
alter table public.site_settings drop column if exists seller_text;
update public.homepage_banners set badge='FLOWGET', button_link='#shop' where lower(coalesce(badge,'')) like '%sparkcart%' or button_link='#seller';
delete from public.homepage_banners where button_link='#seller';
-- Optional cleanup: seller_applications is no longer used by the application.

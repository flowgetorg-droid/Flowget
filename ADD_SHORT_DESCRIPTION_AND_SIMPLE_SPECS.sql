-- FlowGet additive product content update
-- Safe for the existing database: no DROP, TRUNCATE or DELETE.
-- Run once in Supabase SQL Editor.

alter table if exists public.products
  add column if not exists short_description text;

comment on column public.products.short_description is
  'Optional short product summary shown beside price; full description remains in description.';

select pg_notify('pgrst', 'reload schema');

-- FlowGet: enable editable Return & Refund Policy in Admin > Settings.
-- Run once in Supabase SQL Editor.
ALTER TABLE public.website_settings
ADD COLUMN IF NOT EXISTS return_policy text;

-- FlowGet: safe compatibility fix for legacy coupons.value
-- No DROP / TRUNCATE / DELETE. Existing coupon/order data is preserved.

DO $$
BEGIN
  -- Some older FlowGet databases have a NOT NULL coupons.value column,
  -- while the current app uses discount_value.
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='coupons' AND column_name='value'
  ) THEN
    -- Backfill only missing legacy values from the current discount_value.
    EXECUTE 'UPDATE public.coupons SET value = discount_value WHERE value IS NULL AND discount_value IS NOT NULL';
  ELSE
    -- Fresh/current schemas may not have the legacy column at all.
    -- Adding it as nullable keeps this migration safe and non-breaking.
    EXECUTE 'ALTER TABLE public.coupons ADD COLUMN value numeric';
    EXECUTE 'UPDATE public.coupons SET value = discount_value WHERE value IS NULL AND discount_value IS NOT NULL';
  END IF;
END $$;

-- Keep legacy value aligned when discount_value is changed.
CREATE OR REPLACE FUNCTION public.sync_coupon_legacy_value()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.discount_value IS NOT NULL THEN
    NEW.value := NEW.discount_value;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS coupons_sync_legacy_value ON public.coupons;
CREATE TRIGGER coupons_sync_legacy_value
BEFORE INSERT OR UPDATE OF discount_value ON public.coupons
FOR EACH ROW EXECUTE FUNCTION public.sync_coupon_legacy_value();

NOTIFY pgrst, 'reload schema';

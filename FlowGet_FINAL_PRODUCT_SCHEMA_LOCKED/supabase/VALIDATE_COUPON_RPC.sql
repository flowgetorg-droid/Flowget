-- Safe additive migration: validate a coupon for checkout preview.
-- Does not create orders, increment usage, or modify existing data.
create or replace function public.validate_coupon(
  p_code text,
  p_subtotal numeric
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  cp public.coupons%rowtype;
  disc numeric := 0;
  subtotal numeric := greatest(coalesce(p_subtotal,0),0);
  clean_code text := upper(trim(coalesce(p_code,'')));
begin
  if clean_code='' then
    return jsonb_build_object('valid',false,'discount',0,'message','কুপন কোড লিখুন।');
  end if;

  select * into cp
  from public.coupons
  where upper(code)=clean_code
    and active=true
    and (start_at is null or now() >= start_at)
    and (expires_at is null or now() <= expires_at)
  limit 1;

  if not found then
    return jsonb_build_object('valid',false,'discount',0,'message','কুপন কোড সঠিক নয় বা মেয়াদ শেষ।');
  end if;

  if subtotal < coalesce(cp.min_order,0) then
    return jsonb_build_object('valid',false,'discount',0,'message',format('এই কুপনের জন্য ন্যূনতম অর্ডার ৳%s প্রয়োজন।',cp.min_order));
  end if;

  if cp.usage_limit is not null and (select count(*) from public.coupon_usage where coupon_id=cp.id) >= cp.usage_limit then
    return jsonb_build_object('valid',false,'discount',0,'message','এই কুপনের ব্যবহার সীমা শেষ।');
  end if;

  if cp.coupon_type='percentage' then
    disc := least(subtotal * cp.discount_value / 100, coalesce(cp.max_discount,subtotal));
  else
    disc := least(cp.discount_value,subtotal);
  end if;

  disc := greatest(coalesce(disc,0),0);
  return jsonb_build_object(
    'valid',true,
    'discount',round(disc,2),
    'coupon_code',cp.code,
    'message',format('কুপন প্রয়োগ হয়েছে — ছাড় ৳%s',round(disc,2))
  );
end;
$$;

revoke all on function public.validate_coupon(text,numeric) from public;
grant execute on function public.validate_coupon(text,numeric) to anon, authenticated;

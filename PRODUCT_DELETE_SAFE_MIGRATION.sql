

-- Safe product delete/archive: never breaks historical orders.
create or replace function public.admin_delete_product_safe(p_product_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count bigint;
  v_archived boolean := false;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  select count(*) into v_count from public.order_items where product_id = p_product_id;
  if v_count > 0 then
    update public.products set active = false, updated_at = now() where id = p_product_id;
    if not found then raise exception 'product not found'; end if;
    v_archived := true;
  else
    delete from public.product_images where product_id = p_product_id;
    delete from public.products where id = p_product_id;
    if not found then raise exception 'product not found'; end if;
  end if;
  return jsonb_build_object('archived',v_archived,'deleted',not v_archived,'order_item_count',v_count);
end;
$$;
revoke all on function public.admin_delete_product_safe(uuid) from public;
grant execute on function public.admin_delete_product_safe(uuid) to authenticated;

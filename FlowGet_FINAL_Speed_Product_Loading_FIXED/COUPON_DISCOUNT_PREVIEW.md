# Coupon discount preview

This update adds a safe checkout coupon preview. Customers can apply a coupon and immediately see the exact discount and updated total before placing the order.

Supabase: run `supabase/VALIDATE_COUPON_RPC.sql` once. It is additive only; it does not delete, update, or truncate existing orders/coupons/products.

The secure `create_order_secure` RPC remains the final authority and re-validates the coupon when the order is submitted.

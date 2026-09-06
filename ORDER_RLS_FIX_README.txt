SPARKCART ORDER RLS FIX

If customer checkout shows:
new row violates row-level security policy for table "orders"

Run ORDER_RLS_FIX.sql once in Supabase SQL Editor.

This fix only recreates the public INSERT policy for orders.
It does NOT delete or change existing products, product images, product details,
orders, admin data, or order tracking data.

Supported payment methods:
Cash on Delivery, bKash, Nagad, Rocket

The website also allows online payment amount >= the calculated order total.

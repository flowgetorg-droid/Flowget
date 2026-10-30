# FlowGet update notes

## Changes
- Admin > Orders now has a View details row for each order, showing division, district, upazila/thana, full address, order note, and payment method when present in the order record.
- Admin > Settings now includes an editable Return & Refund Policy field.
- The saved policy is shown on `/return-refund-policy` and on individual product pages.
- Admin product editor now shows the individual product URL (`/product/<slug>`) and a Preview page shortcut. Every product already has its own product-detail/landing route based on its slug.

## One-time Supabase step
Run `RETURN_POLICY_MIGRATION.sql` in Supabase SQL Editor before saving the Return & Refund Policy for the first time. This adds one nullable text column and does not alter existing orders, products, reviews, or checkout functions.

## Existing orders
The admin can display address information only if it was saved on the order row. New checkout orders already submit division, district, area, address, and note to `create_order_secure`. Older orders that were created without persisted address values cannot be reconstructed from this frontend update.

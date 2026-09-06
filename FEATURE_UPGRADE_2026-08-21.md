# SparkCart Mall Feature Upgrade — 2026-08-21

## Video analysis applied
- Admin KPI dashboard and sales overview
- 7-day sales chart + top products
- Inventory / low-stock control
- District-level order map
- Order status workflow and order detail modal
- Order CSV export
- Admin WhatsApp action per order
- Customer order tracking (Order ID + phone)
- bKash / Nagad / Rocket checkout with sender number, optional TXID, amount and payment time
- Admin-configurable merchant numbers for bKash / Nagad / Rocket
- Redesigned floating WhatsApp button with logo

## Safety
- No DROP TABLE.
- No DELETE FROM orders/products.
- Existing orders/products/customer/admin records are preserved.
- `FEATURE_UPGRADE_ONLY.sql` contains only the new feature migration and is the safest SQL to run on an already-working SparkCart database.
- `supabase.sql` remains the complete setup/seed file for a fresh database.

## Important
Before accepting online payments, set the bKash/Nagad/Rocket merchant numbers from **Admin → Marketing → Payment Settings**.

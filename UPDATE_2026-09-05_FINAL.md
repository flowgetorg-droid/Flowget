# SparkCart Mall — Final Improvement Update (2026-09-05)

This build keeps the existing Netlify + GitHub + Supabase setup and does not intentionally delete or replace existing product, order, admin, review, cart, checkout, or database data.

## Included updates
- SparkCart Mall logo in the customer header.
- Corrected Kitchen Storage & Accessories icon to a kitchen-themed emoji.
- Cart Order and Quick/Direct Order remain separate.
- Quick/Direct Order now supports quantity +/- before submission and never changes the existing cart.
- bKash/Nagad/Rocket checkout explicitly says **Send Money**.
- Payment recipient numbers are now taken from Admin > Payment Settings; no hardcoded fallback number is used for online payments.
- If an online payment method has no configured recipient number, checkout is blocked with a clear message instead of risking payment to the wrong number.
- Visitor activity tracking remains anonymous and includes visit/page view/product view/add-to-cart/checkout/order-completed events.
- Admin Dashboard now shows today's visitors, product views, add-to-cart events, and visitor-to-order conversion rate.
- Visitor Activity tab remains available for detailed anonymous visitor timelines.
- Existing SEO/product-link functionality is preserved.

## Supabase
- The existing `VISITOR_ACTIVITY_MIGRATION.sql` remains included.
- Run the migration in Supabase SQL Editor if it has not already been applied.
- Do not re-run the full `supabase.sql` seed blindly on a live database. Existing live data should be preserved.

## Validation
- Customer `index.html` JavaScript syntax check: PASS.
- Admin `admin/index.html` JavaScript syntax check: PASS.
- Standalone `admin_script.js` syntax check: PASS.
- ZIP integrity check: PASS.

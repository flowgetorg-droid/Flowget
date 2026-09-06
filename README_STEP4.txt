SparkCart Mall - Step 4 Marketing
===================================
Features:
- Admin coupon management (fixed/percent, min order, max discount, expiry, usage limit)
- Secure-ish server-side coupon validation/redeem functions in Supabase
- Checkout coupon application
- Loyalty points stored in browser (1 point per ৳100, 100 points = ৳50)
- Lucky Spin with Admin-controlled enable/disable, per-customer spin limit, minimum order, reward amounts, and maximum discount
- Flash sale using existing product sale price/old price

DEPLOY:
1. Run supabase.sql in Supabase SQL Editor.
2. Replace repository files with this package contents.
3. Keep index.html at repository root and admin/index.html in /admin.
4. Commit to GitHub; Cloudflare Pages should redeploy automatically.

NOTE:
- Loyalty points and Lucky Spin are browser-local promotional features; they are not account-level rewards.
- Test coupon, checkout total, and existing orders before production.


LUCKY SPIN CONTROL
- Run the updated supabase.sql in Supabase SQL Editor.
- Admin > Marketing > Lucky Spin Control controls ON/OFF, spins per customer, minimum order, reward amounts, and maximum reward.
- Customer spin usage is tracked in the browser (localStorage), so this is a client-side promotional limit. For stronger anti-abuse enforcement, an authenticated/customer-identity based usage table can be added later.

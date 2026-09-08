# FlowGet

Production-oriented React/Vite single-store e-commerce starter for Bangladesh using Supabase and Cloudflare Pages.

## Local test
1. Node.js 20+.
2. Copy `.env.example` to `.env` and add the Supabase project URL and **anon/publishable** key.
3. Run `npm install`.
4. Run `npm run build` to verify the production bundle.
5. Run `npm run dev` for local development.

## Supabase
1. Create a Supabase project.
2. Run `supabase/schema.sql` once in the SQL Editor on a fresh project.
3. Create an Auth user for the administrator.
4. Insert that user's UUID into `admin_users`.
5. If image uploads are needed, create Storage buckets and matching admin policies before enabling uploads. This repository does not contain or expose a service-role key.

## Order security
- Customer prices, stock, coupon eligibility, delivery charge and total are recalculated inside `create_order_secure`.
- Product rows are locked during order creation to prevent overselling.
- Order numbers use an atomic daily counter instead of `count(*) + 1`.
- Coupon per-customer limits are checked server-side.
- Admin cancellation uses `cancel_order_secure`, which restores stock transactionally.
- Payment method is server-side restricted to Cash on Delivery in the current UI.

## Cloudflare Pages
Build command: `npm run build`
Output directory: `dist`
Environment variables: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`

The SPA fallback is in `public/_redirects`, so Vite copies it into `dist/_redirects` during build.

## Important production checks
- Never put a Supabase service-role key in `.env` variables prefixed with `VITE_`.
- Configure Storage buckets/policies if uploads are required.
- Create at least one `admin_users` row for the administrator.
- Seed real products, categories, pages and banners before launch.

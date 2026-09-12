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

## Latest navigation/location fixes
- Admin tab changes use history-only URL updates (`?tab=`), so switching Dashboard/Products/Categories/Orders/Coupons/Banners/Settings does not perform a browser navigation or full page reload.
- Checkout location picker now uses a primary Bangladesh geo API with a nested-JSON fallback and caches successful data locally. Division → District → Upazila/Thana are dependent selectors.

## Latest fixes
- Admin tab navigation is now history-only (`?tab=`), so Dashboard/Products/Categories/Orders/Coupons/Banners/Settings switching does not perform a browser navigation or full page reload, and browser Back/Forward keeps the selected tab.
- Checkout location picker now tries a primary Bangladesh geo API and then the existing nested geo JSON fallback, with local caching. Division → District → Upazila/Thana remain dependent selectors.


### Latest fix
- Removed the fragile `categories(name)` PostgREST relationship from product queries. Product/Admin pages now read `category_id` directly, avoiding schema-cache/relationship errors when the existing Supabase database does not expose the category relationship.

## Latest admin product edit fix
The admin product loader no longer requests a PostgREST embedded `product_images` relationship from `products`. Products are loaded first and gallery rows are fetched separately from `product_images`, avoiding schema-cache errors when the foreign-key relationship is not exposed in PostgREST. Product detail loading uses the same safe approach.

## Final hardening included (2026-09-08)
- Customer Order ID is automatically saved in the browser after successful checkout; Track Order lists saved IDs and lets the customer remove them.
- Admin tab selection and Product Edit draft are persisted in browser storage so navigation and refresh do not silently reset the editing state.
- Product editor has separate Description and Specifications fields.
- Product landing page renders Description and Specifications as separate responsive sections.
- Product gallery is loaded through a separate `product_images` query, avoiding Supabase relationship/schema-cache dependency.
- Schema migration contains additive compatibility fields and safe legacy-value copying. It does not drop tables/columns or truncate/delete existing business data.


## Safe product delete
Run `supabase/PRODUCT_DELETE_SAFE_RPC.sql` once. Products referenced by historical order items are archived (`active=false`) instead of deleted, preserving order history.

## Product schema compatibility

- Product editor sends only real `products` fields; UI-only fields such as `product_images` and `effective_price` are never sent to the table.
- Short Description is stored in `specifications.short_description`, so an older database without a `short_description` column will not block Product Save.
- Product queries have a compatibility fallback for older schemas missing optional filter/sort columns.
- Product gallery is queried separately from `product_images`; missing gallery data does not make the product itself disappear.
- For full database alignment on an existing Supabase project, run `supabase/ADD_PRODUCT_SCHEMA_COMPATIBILITY.sql` once.

## Safe product delete

Run `supabase/PRODUCT_DELETE_SAFE_RPC.sql` once. Products referenced by historical order items are archived (`active=false`) instead of deleted, preserving order history.

## Product schema compatibility (current production)

The current production `products` table has both legacy and current product fields, including `specifications` as `text` and `short_description` as `text`. The frontend is compatible with this production schema and also supports the fresh-schema JSONB `specifications` format.

The admin product editor never spreads the entire form into `products`. UI-only fields such as `product_images` and generated `effective_price` are excluded. Gallery rows are stored in `product_images` separately.

For the GitHub-connected Cloudflare Pages project, upload the **contents of the project root** to the repository's `main` branch. Do not create an extra `FlowGet_FINAL.../` parent directory inside the repository.


### Checkout location note
উপজেলা / থানা (Area) is optional. Customers can place an order with Division and District selected even if they leave Thana/Upazila blank.

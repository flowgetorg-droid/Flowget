# FlowGet update — 2026-11-03

## Changes in this update
- Home banner now rotates through active banners every 6 seconds when multiple active banners exist; previous/next and dot controls are included.
- Banner images use responsive `<picture>` sources and an actual `<img>` element rather than a CSS background. This improves mobile/desktop image loading behavior and keeps the page from needing a reload to change banners.
- Homepage sections load independently, so one failed Supabase request no longer prevents all other homepage data from displaying.
- Homepage banner/category/product data refreshes when the tab becomes visible or focused and on a 2-minute interval. This refresh does not reload the entire website.
- Visitor tracking writes one page_view event per route visit; the five-minute heartbeat updates the visitor session without creating duplicate page_view events.
- Added privacy-conscious event tracking for product views, add-to-cart, checkout starts and order-success purchase events.
- Admin dashboard now shows these four event counts for the last 30 days alongside visitor counts.

## Important notes
- Analytics events are best-effort: if Supabase RLS or the database schema blocks inserts/selects, the storefront remains usable but event counts may be incomplete. Confirm `analytics_events` permits the intended anonymous inserts and admin-only reads using your existing secure RLS rules.
- Purchase tracking uses the order ID stored by the existing checkout flow and deduplicates in the current browser session. Validate the actual `create_order_secure` response fields and analytics event policies after deployment.
- This environment could not complete `npm install`, so a Vite production build could not be run here. Deploy to a preview/staging branch first and check browser console plus Supabase logs before replacing the live production deployment.
- No SQL migration is included or required by these frontend changes.

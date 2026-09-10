# FlowGet product schema compatibility

The admin product editor is designed to work with both the current production database and a fresh FlowGet schema.

## Verified production `products` columns

The current production database contains these product columns:

`id, name, category, price, old_price, discount, rating, reviews, image, stock, badge, featured, active, created_at, updated_at, details, specifications, sku, video_url, images, colors, sizes, seo_title, meta_description, low_stock_threshold, category_id, brand, discount_price, main_image, review_count, new_arrival, flash_deal, is_best_selling, effective_price, description, slug, short_description`

## Important compatibility behavior

- Product reads use `select('*')`; no fragile embedded category or gallery relationship is requested.
- Gallery rows come from `product_images` separately.
- The editor sends only real product fields; UI-only fields such as `product_images` and `effective_price` are never sent.
- `short_description` is sent when available, but a stale PostgREST schema cache can cause that single field to be removed and the write retried.
- `specifications` supports both the production TEXT type and the fresh-schema JSONB type. The editor retries with plain text when connected to the legacy TEXT column.
- Existing products and order history are not deleted or truncated by the application.

## Deployment

Push the project root (the contents of this ZIP, not an extra parent folder) to the GitHub `main` branch used by Cloudflare Pages.

Cloudflare Pages:

- Build command: `npm run build`
- Output directory: `dist`
- Root directory: `/`

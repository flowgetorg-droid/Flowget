# Product page loading/speed fix

- Product pages no longer show `Product not found.` while the Supabase request is still loading.
- The product record is rendered as soon as the product query returns.
- Product gallery images load separately after the product appears, so a slow gallery query does not delay the initial product page.
- Query-string links such as Facebook `?fbclid=` remain supported.
- No database schema or existing product/order data is changed.

SparkCart Mall — Daraz-style marketplace upgrade

Added:
- Responsive marketplace home UI
- Hero slider + countdown Flash Sale
- Category tiles
- Smart search with brand + min/max price + stock + sorting
- Mobile bottom navigation
- Become a Seller application form
- Admin Seller Applications review/approve/reject
- Product Brand field and brand filter
- Existing cart, wishlist, checkout, COD, bKash/Nagad/Rocket, coupons, reviews, order tracking and inventory retained

Supabase:
Run SPARKCART_FEATURES_MIGRATION.sql once. It is additive and does not seed/delete products.

Payment note:
The current bKash/Nagad/Rocket flow is manual payment confirmation. Debit/credit card requires a licensed gateway/API and server-side verification; card numbers are not stored by this upgrade.

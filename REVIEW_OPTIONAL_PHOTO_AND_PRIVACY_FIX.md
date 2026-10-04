# Customer Review fixes

- Review photos are optional; customers can submit a review with only a name, star rating and text.
- After submission, the customer sees a neutral thank-you message and is not told that an admin approval step is pending.
- Reviews remain hidden from the public until an admin approves them; approved reviews appear on the product page.

## Existing Supabase database
Run `CUSTOMER_REVIEWS_PHOTO_MIGRATION.sql` once if your existing database has `reviews.photo_url` marked NOT NULL. It safely makes that column nullable and preserves existing reviews and orders.

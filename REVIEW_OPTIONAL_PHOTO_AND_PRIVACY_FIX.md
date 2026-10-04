# Customer Review fixes

- Review photos are optional; customers can submit a review with only a name, star rating and text.
- After submission, the customer sees a neutral thank-you message and is not told that an admin approval step is pending.
- Reviews remain hidden from the public until an admin approves them; approved reviews appear on the product page.

## Existing Supabase database
Run `CUSTOMER_REVIEWS_PHOTO_MIGRATION.sql` once if your existing database has `reviews.photo_url` marked NOT NULL. It safely makes that column nullable and preserves existing reviews and orders.


### RLS submit fix
The review form previously used Supabase `.insert(...).select('id').single()`. Because customer submissions are stored with `approved=false` and public SELECT is restricted to approved reviews, the chained SELECT attempted to read the newly inserted unapproved row and could surface `new row violates row-level security policy for table "reviews"`. The frontend now performs INSERT only and returns success without reading the private/unapproved row.

If the deployed database is missing the intended INSERT policy, run `CUSTOMER_REVIEWS_RLS_FIX.sql` once in Supabase SQL Editor.

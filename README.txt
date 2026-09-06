SPARKCART MALL — MOBILE ADMIN FINAL

FILES
- index.html                 = customer website
- admin/index.html           = mobile-friendly admin dashboard
- supabase.sql               = products + orders + admin + image storage setup

WHAT THE ADMIN CAN DO
- Login with Supabase Auth
- View/search/filter orders
- Change order status
- Open full order details
- Add products
- Edit products
- Delete products
- Hide/show products
- Set stock, price, old price, badge, featured
- Upload product images from phone/PC
- All changes appear on the customer website automatically

IMPORTANT FIRST STEP
1. Supabase Dashboard -> SQL Editor
2. Paste/run the complete supabase.sql ONCE.
3. Supabase Dashboard -> Authentication -> Users
4. Make sure the admin account exists:
   sparkcartmallbd@gmail.com
   Use the password you already set for this account.
5. If that account did not exist when the SQL was run, create it and run the admin insert section again:
   insert into public.admin_users(user_id,email)
   select id,email from auth.users
   where lower(email)=lower('sparkcartmallbd@gmail.com')
   on conflict(user_id) do update set email=excluded.email;

GITHUB / NETLIFY
Upload the CONTENTS of this folder to the GitHub repository connected to Cloudflare Pages.
Do not upload the ZIP itself.

After Cloudflare Pages deploys:
Customer: https://YOUR-SITE.Cloudflare Pages.app/
Admin: https://YOUR-SITE.Cloudflare Pages.app/admin/

SECURITY
- Only the public/publishable Supabase key is used in browser code.
- Never put a service_role/secret key into index.html or admin/index.html.
- Admin data access is protected by Supabase Auth + admin_users RLS.


STEP 1 PRODUCT SYSTEM
- Multiple photos, product video, details, specifications, SKU, colors, sizes, stock, sale price/discount.
- Run the updated supabase.sql before deploying.
- Product media uses the existing public product-images bucket.


PRODUCT CATALOG UPDATE
- 50 Bangladesh-focused products added.
- SEO fields: seo_title + meta_description.
- See MARKET_ANALYSIS_2026.md and PRODUCT_CATALOG_DEPLOYMENT.txt.
- Seed SQL is in supabase.sql.

# FlowGet

Production-oriented React/Vite single-store e-commerce starter for Bangladesh using Supabase and Cloudflare Pages.

## Contact

- **WhatsApp:** +880 1822-024595
- **Email:** flowget.org@gmail.com

## Local development

Requirements:
- Node.js 20+
- npm

Steps:

1. Copy `.env.example` to `.env`.
2. Add your Supabase project URL and **anon/publishable** key.
3. Install dependencies:

```bash
npm install
```

4. Verify the production build:

```bash
npm run build
```

5. Start local development:

```bash
npm run dev
```

Do not commit `.env` or any Supabase service-role/secret key.

## Supabase setup

1. Create a Supabase project.
2. Open **SQL Editor**.
3. Run the included `supabase/schema.sql` on a fresh project.
4. If the database already contains an older/partial FlowGet schema, use the current final schema/migration SQL supplied for that database rather than blindly recreating tables.
5. Create the administrator in **Authentication → Users**.
6. Copy the Auth user's UUID.
7. Add the administrator to `public.admin_users`, including the email if the column is required:

```sql
insert into public.admin_users (user_id, email)
values ('YOUR_AUTH_USER_UUID', 'your-admin-email@example.com');
```

8. Seed real categories, products, pages and banners before launch.
9. If direct image uploads are enabled later, create the required Supabase Storage buckets and matching admin policies.

The application must never expose a Supabase service-role key in frontend code or in variables prefixed with `VITE_`.

## Admin panel

After the administrator is added to `public.admin_users`, sign in through the application.

The admin panel supports management of:
- Products
- Categories
- Coupons
- Homepage banners
- Orders and order status
- Website/static pages
- Website settings

Current image management uses image URLs where upload UI is not enabled.

## Order security

The production schema is designed so important order calculations are performed server-side:

- Product prices are recalculated from the database.
- Stock is checked and product rows are locked during order creation to reduce overselling.
- Coupon eligibility and per-customer limits are checked server-side.
- Delivery charge and final total are recalculated server-side.
- Order numbers use an atomic daily counter.
- Secure cancellation restores stock transactionally.
- The current checkout/payment flow is Cash on Delivery.

## Cloudflare Pages deployment

### 1. Push the project to GitHub

Upload the **extracted project files**, not only the ZIP file.

Do not upload:
- `.env`
- Supabase service-role keys
- private credentials

### 2. Create a Cloudflare Pages project

In Cloudflare:

**Workers & Pages → Create application → Pages → Connect to Git**

Select the GitHub repository.

### 3. Build configuration

Use:

- **Framework preset:** React (Vite)
- **Build command:** `npm run build`
- **Build output directory:** `dist`
- **Root directory:** `/`

The project uses Vite, so Cloudflare must run the build step. Do not leave the build command blank.

### 4. Environment variables

Add these variables in Cloudflare Pages:

```text
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_or_publishable_key
```

Use the Supabase **anon/publishable** key for the frontend.

Never put a service-role/secret key in a `VITE_` variable.

### 5. Deploy

Save the settings and deploy.

Cloudflare should run approximately:

```text
npm install
npm run build
```

A successful Vite build creates:

```text
dist/
```

The SPA fallback file is:

```text
public/_redirects
```

Vite copies it into:

```text
dist/_redirects
```

This is required so routes such as `/shop`, `/product/...`, `/cart`, `/checkout`, and `/admin` work correctly on direct navigation.

## Post-deployment smoke test

After deployment, verify:

### Customer flow
- Homepage loads without console MIME/module errors.
- Shop page loads.
- Search works.
- Product details load.
- Add to cart works.
- Cart quantity updates correctly.
- Stock limits are respected.
- Checkout validates Bangladesh phone numbers.
- Coupon validation works when configured.
- Order creation succeeds.
- Order tracking works.
- Cancellation/status behavior matches the admin workflow.

### Admin flow
- Admin login works.
- Non-admin users cannot access admin data/actions.
- Products can be created and edited.
- Categories can be managed.
- Coupons can be managed.
- Banners can be managed.
- Orders can be updated/cancelled.
- Static pages/settings can be managed.

### Contact
- WhatsApp button opens the FlowGet WhatsApp contact.
- Email link opens `flowget.org@gmail.com`.

## Production checklist

Before launch:

- [ ] Cloudflare Pages uses **React (Vite)**.
- [ ] Build command is `npm run build`.
- [ ] Output directory is `dist`.
- [ ] `VITE_SUPABASE_URL` is configured.
- [ ] `VITE_SUPABASE_ANON_KEY` is configured.
- [ ] No service-role key is exposed through `VITE_`.
- [ ] Supabase schema is installed successfully.
- [ ] At least one administrator exists in `public.admin_users`.
- [ ] Real products/categories are seeded.
- [ ] Homepage banners are configured.
- [ ] Required static/legal pages are populated.
- [ ] Storage policies are configured if uploads are enabled.
- [ ] Production build completes successfully.
- [ ] Customer checkout and order tracking have been tested.
- [ ] Admin order/product management has been tested.
- [ ] WhatsApp and email contact links have been tested.

## Project contact

For customer support and store contact:

**WhatsApp:** +880 1822-024595  
**Email:** flowget.org@gmail.com

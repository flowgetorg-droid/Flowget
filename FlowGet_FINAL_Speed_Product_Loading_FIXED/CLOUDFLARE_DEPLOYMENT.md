# Cloudflare Pages deployment

1. Push the project to GitHub.
2. Cloudflare Dashboard → Workers & Pages → Create → Pages → Connect to Git.
3. Framework preset: **Vite**.
4. Build command: `npm run build`.
5. Build output directory: `dist`.
6. Add production variables:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
7. Deploy.
8. Verify direct refreshes for `/`, `/shop`, `/product/<slug>`, `/category/<slug>`, `/cart`, `/checkout`, `/track-order` and `/admin`.

The SPA fallback is stored at `public/_redirects` and is copied to `dist/_redirects` by Vite.

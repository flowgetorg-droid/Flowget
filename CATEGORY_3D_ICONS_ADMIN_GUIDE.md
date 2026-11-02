# FlowGet category 3D icons

- Open Admin Panel → Categories.
- Add a category or click Edit for an existing category.
- Upload a transparent PNG/WebP 3D icon using the image input, or paste an image URL into the `icon` field.
- Save the category. The same `categories.icon` field is used, so no database migration is required.
- Recommended icon assets: square 1:1 transparent PNG/WebP, around 256–512 px, preferably under 8 MB.

Existing emoji/text icons continue to work. Uploaded images are stored in the existing `product-media` Supabase Storage bucket under `categories/`.

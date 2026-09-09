# FlowGet Product Catalog Update

This build adds:

- Product specification name dropdown (Color, Size, Material, Weight, Dimensions, Battery, Capacity, Warranty, Model, Brand, Compatibility, Other/custom)
- More reliable Supabase Storage uploads for product images/video
- Admin gallery upload with previews
- Six useful Bangladesh-focused categories
- Ten realistic demo products with prices, descriptions, specifications, ratings, stock and image URLs
- Individual product landing pages at `/product/<slug>`
- Product cards show a direct **View product →** link
- Product landing page supports gallery thumbnails, video, specifications, Buy Now/Add to Cart and copy-link

## Required Supabase step

Run `FlowGet_Product_Catalog_And_Image_Fix.sql` in Supabase SQL Editor before deploying this build. It creates/repairs the product media Storage policies and seeds the catalog.

## Demo image note

The seeded demo images use Unsplash image URLs. Replace them with your own supplier/product photos later from Admin → Products → Choose File.

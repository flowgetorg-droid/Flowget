# Dhaka Thana Location Fix

Updated `src/data/bangladesh.js` so the checkout address picker includes the full 49 Dhaka Metropolitan Police (DMP) police-station list for Dhaka district, while preserving the existing Bangladesh division/district/upazila API data.

## What changed
- Added 49 DMP police stations as a local Dhaka fallback/merge list.
- Merged the DMP list into the existing Dhaka district location data instead of replacing existing data.
- Kept the existing 5 administrative Dhaka District upazilas when the API supplies them.
- Bumped the browser location-cache key from `v4` to `v5`, so users do not stay stuck on the old incomplete cached list.
- Applied the merge to both primary API data and the secondary geo-data fallback.
- No Supabase schema, product/order data, or existing database records were changed.

## Verification
- JavaScript syntax check passed for `src/data/bangladesh.js`.
- Verified 49 unique DMP police-station entries are present.
- The package build could not be completed in this environment because `npm install` did not finish before the execution timeout; no source/build error was reported by Vite because dependencies could not be installed here.


## Checkout requirement update
- উপজেলা / থানা is optional at checkout; customers can place an order without selecting it.
- Frontend `required` validation and submit validation were removed for this field.
- The Supabase `orders.area` column already allows NULL, and `create_order_secure` accepts the value without requiring it, so no database migration is needed.

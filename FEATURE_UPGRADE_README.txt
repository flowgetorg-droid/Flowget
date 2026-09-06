SparkCart Mall — Feature Upgrade

1. Supabase:
   Run ONLY: SPARKCART_FEATURES_MIGRATION.sql

2. GitHub/Netlify:
   Replace the website files with the contents of this ZIP.
   This version contains the customer tracking UI, online-payment form,
   WhatsApp actions, product deep links, admin payment settings,
   payment information in order details, dashboard inventory and order map.

3. IMPORTANT:
   Do NOT run supabase.sql for this upgrade. It contains product seed data.
   No old orders/products/customers are deleted by the feature migration.

4. Admin:
   Login -> Marketing -> Payment Settings -> enter your real bKash/Nagad/Rocket number.

5. Product links:
   https://sparkcartmall.netlify.app/?product=SKU
   Example: ?product=SC-GAD-001

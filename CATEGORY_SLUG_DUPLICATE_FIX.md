# FlowGet Category Slug Duplicate Fix

The category editor now checks whether a slug is already in use before inserting or updating a category. If a duplicate is found, it shows a clear message rather than the raw PostgreSQL unique-constraint error. It allows saving when editing the category that already owns that slug. No database migration is required.

## What to do if you see the message
- To add a genuinely new category, enter a unique slug (for example `home-kitchen` instead of a slug already used by another category).
- To change an existing category icon/name, click **Edit** on that category instead of adding it again.
- Existing categories and product data are not deleted or modified by this fix.

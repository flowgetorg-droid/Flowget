# FlowGet data preservation note

This final package was checked for destructive database statements.

- No `DROP TABLE`
- No `TRUNCATE`
- No `DELETE FROM`
- No `DROP COLUMN`

The schema uses `CREATE TABLE IF NOT EXISTS` and `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` for compatibility. Legacy product category/order fields are copied into the current canonical fields only when the canonical value is empty.

Important: the package cannot inspect the live Supabase rows from this offline build workspace. Existing live rows should therefore still be backed up in Supabase before running any schema migration as a normal production precaution.

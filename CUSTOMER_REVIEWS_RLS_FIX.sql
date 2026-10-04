-- FlowGet Customer Reviews RLS Fix
--
-- The frontend inserts reviews with approved=false and intentionally does not
-- read the inserted row back. Public SELECT remains limited to approved reviews.
-- This migration safely recreates the anonymous/authenticated INSERT policy.

alter table public.reviews enable row level security;

drop policy if exists "public reviews insert" on public.reviews;
create policy "public reviews insert"
on public.reviews for insert
to anon, authenticated
with check (
  approved = false
  and rating between 1 and 5
  and char_length(trim(coalesce(customer_name, ''))) between 2 and 80
  and char_length(trim(coalesce(review_text, ''))) between 5 and 1000
  and exists (
    select 1
    from public.products p
    where p.id = reviews.product_id
      and p.active = true
  )
);

-- Keep this unchanged: unapproved customer reviews must NOT be publicly readable.
-- Public SELECT should remain: approved = true.

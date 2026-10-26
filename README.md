# SHADOW UCHIHA — Starter Package

This is a front-end prototype, not a finished streaming platform.

## Included
- `index.html` — responsive anime website prototype with search, genre filters, anime details and device-local watchlist
- `supabase/schema.sql` — starter database tables and basic row-level security
- `SETUP-TE-EN.md` — Android/GitHub upload guide
- `privacy.html`, `terms.html`, `copyright.html` — policy page drafts
- `_headers` — basic security headers for Cloudflare Pages
- `_redirects` — simple fallback

## Important
- No Firebase Storage is used.
- Login, real admin approval, upload and live video playback are not connected yet.
- Sample titles are placeholders. Add only media you own or are authorized to distribute.
- Never put a Supabase service-role key or other secrets in public files.
- Do not enable paid billing. Pause features when free-tier limits are reached.

## Free-tier limits checked 2026-10-26
- Cloudflare Pages Free: 500 builds/month, up to 20,000 files and 25 MiB per site asset. https://developers.cloudflare.com/pages/platform/limits/
- Supabase Free: 2 active projects, 500 MB database per project, 1 GB storage, 5 GB egress and 50,000 monthly active users; free projects may pause after one week of inactivity. https://supabase.com/pricing
- Cloudinary Free: max video file size 100 MB and 25 monthly credits. It does not guarantee 100–500 MB uploads. https://cloudinary.com/pricing/compare-plans

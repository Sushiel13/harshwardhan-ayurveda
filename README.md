# Harshwardhan Institute of Ayurveda

A complete online-learning platform for BAMS students and Ayurveda aspirants: a premium website, one mobile app for students **and** the owner/admin, secure video courses, timed test series, eBooks, free notes, live classes, coupons and Razorpay payments.

```
harshwardhan-ayurveda/
├── web/        Next.js 14 website + web admin panel + payment API
├── mobile/     Flutter app (Android & iOS) — student app with built-in admin panel
├── supabase/   Database schema, security rules, sample data
└── docs/       Setup, owner/admin guide, student guide
```

## Features

**Students** — browse courses by exam, free previews, buy with UPI/cards (Razorpay), coupons, secure HD video player with progress tracking and notes PDFs, timed tests with negative marking and explained solutions, eBooks, free notes, live classes with “Join now”, announcements, one login across web and app.

**Owner / admin** (website `/admin` and inside the app) — revenue dashboard, create courses with sections and video/PDF lessons, set prices, MRP discounts and validity, publish/feature, test series with question editor and bulk import, eBooks, free notes, live-class scheduling, announcements, coupons, student search, grant/revoke access, block users, promote admins, payments with CSV export, contact inquiries, site settings.

## How it fits together

| Layer | Technology | Notes |
|---|---|---|
| Database, login, file storage | Supabase (Postgres) | Row-Level Security enforces who can see what; paid videos/eBooks live in a private bucket and are served through expiring signed links |
| Website & admin | Next.js 14, Tailwind CSS | Deployed on Vercel |
| Payments | Razorpay | Orders created & verified server-side in `web/src/app/api/razorpay/*` (+ webhook safety net). The app uses the same endpoints |
| Mobile app | Flutter 3.27+ | Admins see the admin panel after login; can switch to student view |

Prices are always calculated on the server, so they can't be tampered with in the browser or app.

## Quick start

1. **Backend:** create a Supabase project → run `supabase/migrations/001_schema.sql`, then `supabase/seed.sql`.
2. **Website:** `cd web && cp .env.example .env.local` (fill values) `&& npm install && npm run dev`.
3. **Admin:** sign up, then run `supabase/make_admin.sql` with your email.
4. **App:** `cd mobile && bash setup_platforms.sh && cp env.example.json env.json` (fill values) `&& flutter run --dart-define-from-file=env.json`.

Full instructions: **[docs/SETUP_AND_DEPLOYMENT.md](docs/SETUP_AND_DEPLOYMENT.md)**

## Documentation

- [Setup & deployment](docs/SETUP_AND_DEPLOYMENT.md) — Supabase, Razorpay, Vercel, Play Store, going-live checklist
- [Owner & admin guide](docs/OWNER_ADMIN_GUIDE.md) — how to upload videos, manage prices, tests, coupons, students and payments
- [Student guide](docs/STUDENT_GUIDE.md) — share with students or link from the website

## Before going live

Replace the sample content, contact details (`web/src/lib/site.ts` and Admin → Settings) and placeholder store links; have the template policies in `web/src/app/policies` reviewed by a legal adviser.

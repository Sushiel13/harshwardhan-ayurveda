# Setup & Deployment Guide

This guide takes you from an empty account to a live website, a working payment flow and an Android app on the Play Store. Allow about half a day the first time.

You will need accounts on: **Supabase** (database, login, file storage), **Razorpay** (payments), **Vercel** (website hosting), **GitHub** (code), and a **Google Play Console** developer account (₹2,100 one-time, approx.) for the app. An Apple Developer account is only needed if you also publish on iPhone.

---

## 1. Supabase (backend)

1. Go to supabase.com → **New project**. Choose region **Mumbai (ap-south-1)** for the fastest experience in India. Save the database password somewhere safe.
2. Open **SQL Editor** → New query → paste the full contents of `supabase/migrations/001_schema.sql` → **Run**.
3. New query → paste `supabase/seed.sql` → **Run**. This adds sample categories, courses and a sample test so the site doesn't look empty. You can edit or delete all of it later from the Admin panel.
4. **Authentication → Providers → Email**: keep it enabled. Decide whether students must confirm their email:
   - *Confirm email ON* (recommended) — fewer fake signups.
   - *Confirm email OFF* — faster signup, students are logged in immediately.
5. **Authentication → URL Configuration**: set *Site URL* to your website address (e.g. `https://harshwardhanayurveda.in`) and add `https://harshwardhanayurveda.in/reset` to *Redirect URLs*.
6. **Project Settings → API**: copy the *Project URL*, the *anon public* key and the *service_role* key. You'll need them below. **Never put the service_role key in the mobile app or share it.**

### Storage size for videos
- Storage buckets `media` (public) and `content` (private) are created by the SQL script.
- The Supabase **Free** plan limits each uploaded file to 50 MB — fine for testing, too small for lecture videos.
- On the **Pro** plan raise the limit at **Project Settings → Storage → Upload file size limit** (e.g. 2 GB).
- For a large library (hundreds of hours), consider hosting videos on **Bunny Stream** or **Vimeo** and pasting the link into the lesson's *“…or video link”* field. Both support domain restriction so links can't be reused elsewhere. Avoid unlisted YouTube for paid content — anyone with the link can share it.

## 2. Razorpay (payments)

1. Sign up at razorpay.com and complete KYC (needed for live payments; test mode works immediately).
2. **Account & Settings → API Keys** → generate keys. Start with **Test** keys.
3. **Webhooks → Add new webhook**
   - URL: `https://YOUR-DOMAIN/api/razorpay/webhook`
   - Secret: any long random string — use the same value for `RAZORPAY_WEBHOOK_SECRET`
   - Events: `payment.captured` and `order.paid`
   The webhook is a safety net: even if a student closes the page right after paying, their access is still granted.
4. When you are ready to accept real money, switch to **Live** keys and create the webhook again in Live mode.

**Test card for Test mode:** Razorpay publishes test card and UPI details in their docs (search “Razorpay test cards”).

## 3. Website (Vercel)

1. Push this repository to GitHub (see section 6).
2. vercel.com → **Add New → Project** → import the repo.
3. **Root Directory:** `web`  · Framework preset: Next.js (auto-detected).
4. **Environment Variables** (copy names from `web/.env.example`):

   | Name | Value |
   |---|---|
   | `NEXT_PUBLIC_SUPABASE_URL` | Supabase Project URL |
   | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon key |
   | `SUPABASE_SERVICE_ROLE_KEY` | Supabase service_role key |
   | `NEXT_PUBLIC_RAZORPAY_KEY_ID` | Razorpay Key ID |
   | `RAZORPAY_KEY_SECRET` | Razorpay Key Secret |
   | `RAZORPAY_WEBHOOK_SECRET` | the webhook secret you chose |
   | `NEXT_PUBLIC_SITE_URL` | `https://your-domain` |

5. **Deploy**. Then **Settings → Domains** → add your domain (e.g. `harshwardhanayurveda.in`) and follow the DNS instructions from your domain registrar.

### Running the website on your computer
```bash
cd web
cp .env.example .env.local   # fill in the values
npm install
npm run dev                  # open http://localhost:3000
```

### Branding & contact details on the website
Edit `web/src/lib/site.ts` — phone, WhatsApp, email, address, Play Store / App Store links. Redeploy (Vercel does this automatically on every push to GitHub).

## 4. Make the owner an admin

1. Sign up on the website (or app) with the owner's email.
2. Supabase → SQL Editor → open `supabase/make_admin.sql`, replace the email, **Run**.
3. Log out and back in. The **Admin** button now appears on the website, and the app opens straight into the Admin panel.

After that, the owner can promote other staff to admin from **Admin → Students → ⋮ → Make admin**.

## 5. Mobile app (Android & iPhone)

Requirements on the build computer: Flutter SDK (3.27 or newer), Android Studio; for iPhone, a Mac with Xcode.

```bash
cd mobile
bash setup_platforms.sh          # one-time: generates android/ and ios/ folders
cp env.example.json env.json      # fill in Supabase URL, anon key, and your website URL
flutter run --dart-define-from-file=env.json   # run on a connected phone/emulator
```

`API_BASE_URL` must be your **live website address** — the app uses the website's payment endpoints, so payments in the app work once the website is deployed with Razorpay keys.

### Publishing on Google Play
1. Create an upload key once:
   `keytool -genkey -v -keystore ~/hia-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Follow Flutter's “Build and release an Android app” guide to reference the key in `android/key.properties` (this file is git-ignored — keep it and the `.jks` file backed up; you cannot update the app without them).
3. Build: `flutter build appbundle --release --dart-define-from-file=env.json`
4. Play Console → Create app → upload `build/app/outputs/bundle/release/app-release.aab` → fill store listing, content rating, data safety form (you collect name, email, phone; payments are processed by Razorpay) → submit for review.
5. Put the Play Store link into `web/src/lib/site.ts` (`playStoreUrl`).

### Publishing on the App Store (optional)
Build with `flutter build ipa --release --dart-define-from-file=env.json`, then upload via Xcode → Organizer or Transporter. Note: Apple's rules on selling digital content inside iOS apps differ from Android; review Apple's App Store guidelines on in-app purchases before enabling paid content in the iOS build.

## 6. Pushing to GitHub

```bash
cd harshwardhan-ayurveda          # the repository root
git init && git add . && git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<you>/<repo>.git
git push -u origin main
```
`.env.local`, `env.json`, signing keys and `node_modules` are git-ignored — never commit secrets.

## 7. Going-live checklist

- [ ] Supabase on Pro plan (or external video host) and upload limit raised
- [ ] Email confirmation decision made; Site URL + redirect URL set
- [ ] Razorpay **Live** keys in Vercel + Live webhook created
- [ ] Owner account promoted to admin
- [ ] Sample seed content replaced with real courses, prices and testimonials
- [ ] Contact details updated in `web/src/lib/site.ts` and Admin → Settings
- [ ] Policies (`/policies/terms`, `privacy`, `refund`) reviewed by a legal adviser
- [ ] One full test purchase made in Live mode (then refund it from the Razorpay dashboard)
- [ ] Supabase **Database → Backups** confirmed (daily backups are on Pro plan)

## 8. Troubleshooting

| Problem | Fix |
|---|---|
| “Your project's URL and API key are required” | Environment variables missing in Vercel / `.env.local` |
| Payment succeeds but course stays locked | Check the webhook URL and secret; open Admin → Payments → *Started* to see the order; grant access manually from Admin → Students |
| Video upload fails at ~50 MB | Free-plan file limit — upgrade, raise the limit, or use a video link |
| Student says they can't log in on the app | They must use the same email + password as the website; use “Forgot password” |
| App payments fail but website works | `API_BASE_URL` in `env.json` must be the live https website address |

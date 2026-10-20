# Owner & Admin Guide

This guide is for the teacher/owner who runs **Harshwardhan Institute of Ayurveda**. Everything here can be done from **two places** — use whichever is convenient:

- **Website:** log in → click **Admin** (top right) → the admin panel opens at `/admin`.
- **Mobile app:** log in with your admin account → the app opens directly in the **Admin panel**. Tap 👁 (top right) to see the app the way students see it, and **Back to admin panel** on the *Me* tab to return.

Changes appear for students instantly on both the website and the app.

> Tip: Bulk question import and CSV payment export are on the website only. Everything else works on both.

---

## 1. Dashboard (Overview)

Shows revenue for the last 30 days and all time, number of students, paid orders, enrolments and your latest sales. Quick buttons let you create a course, schedule a live class, send an announcement or create a coupon.

## 2. Courses & videos

### Create a course
1. **Courses & videos → Add new**.
2. Fill in:
   - **Title** and **Short subtitle** — shown on course cards.
   - **Description** — the “About this course” section.
   - **Category / exam** — e.g. BAMS 1st Prof, AIAPGET. Students filter by this.
   - **Thumbnail** — a wide image (16:10, e.g. 1600×1000 px). If you skip it, an elegant branded cover is generated automatically.
   - **Free course?** — turn on for free courses (price is ignored).
   - **Selling price (₹)** and **MRP (₹)** — MRP shows crossed out with a “% off” badge. Leave MRP empty if you don't want a discount badge.
   - **Access validity (days)** — e.g. 365. Leave empty for lifetime access.
   - **Feature on home page** — show it in “Flagship programmes”.
   - **Published** — keep **off** while you're still uploading; turn **on** when ready. Unpublished courses are invisible to students.
3. **Save**.

### Add sections and lessons
1. Click the course **title** (website) or tap the course (app).
2. **+ Section** — e.g. “Chapter 1 — Padartha Introduction”. Sections are optional but make long courses easier to follow.
3. **+ Lesson**:
   - **Lesson title**, **Section**.
   - **Type:** *Video* or *PDF only*.
   - **Upload video (MP4)** — the file is stored privately. Only students who bought the course (or everyone, if it's a preview) can stream it. Students cannot download it from the player.
   - **…or video link** — paste a Bunny Stream / Vimeo / YouTube link instead of uploading. Used only when no file is uploaded.
   - **Attach notes PDF** — students see a *Notes PDF* button under the video.
   - **Duration (minutes)** — shown in the curriculum.
   - **Free preview** — anyone can watch this lesson without buying. Make 1–2 good lessons previews; it increases sales.
4. Re-order lessons with ↑ ↓ (website) or ⋮ → *Move up/down* (app).
5. A red **“no video”** tag means a video lesson has nothing attached yet.

**Video tips**
- Export as MP4 (H.264), 720p is a good balance of quality and size. A 1-hour 720p lecture is typically 500 MB–1 GB.
- Upload on a stable Wi-Fi connection. Keep the page/app open until the upload finishes.
- If uploads stop at about 50 MB, the storage plan limit needs raising (see Setup guide §1).

### Change the price
Open the course → **Edit** (✏️ on website, ⋮ → Edit in app) → change **Selling price** → **Save**. The new price applies to new purchases immediately. Students who already bought keep their access.

### Delete a course
✏️ / ⋮ → **Delete**. This removes its lessons too. Students who bought it will lose it from their dashboard — usually it's better to just turn **Published** off.

## 3. Test series

1. **Test series → Add new** → title, description, price/free, validity, **Published**.
2. Open the series → **Add new** test:
   - **Duration (minutes)** — the timer. The test auto-submits when time runs out.
   - **Marks per correct answer** (e.g. 4) and **Negative marks per wrong answer** (e.g. 1). Use 0 for no negative marking.
   - **Order** — the position in the list.
3. Click **Questions →** next to a test:
   - **+ Question** — type the question, fill options, select the radio button next to the **correct** answer, add an explanation (shown after submission).
   - **Bulk import** (website) — paste many questions at once in this format, with an empty line between questions:

```
Q: Which dosha is predominant in old age?
A) Kapha
B) Pitta
C) Vata
D) None of these
ANS: C
EXP: Vriddhavastha is Vata-predominant.

Q: Next question…
A) …
B) …
ANS: A
```
   Up to 6 options (A–F) are supported. `EXP:` is optional.

Students see their score, correct/wrong/skipped counts and a full solution review after submitting. Their recent scores appear on their dashboard.

## 4. eBooks

**eBooks → Add new** → title, author, description, **cover** (portrait 3:4), **eBook PDF**, price/free, **Published**. The PDF is private; only buyers can open it (through a link that expires after 30 minutes).

## 5. Free notes

**Free notes → Add new** → title, **subject** (notes are grouped by subject on the site), short description, **PDF file**. Free notes are public — anyone can download them, no login needed. They're a great way to attract new students.

## 6. Live classes

1. Create a meeting in Zoom / Google Meet / YouTube Live.
2. **Live classes → Add new** → title, description, **Starts at**, duration, paste the **Meeting link**.
3. Choose who can join:
   - **Only for students of course:** pick a course → only buyers of that course see the link.
   - Leave course empty → every logged-in student sees the link.
   - **Open to everyone** → even visitors who aren't logged in.
4. Ten minutes before the start time, the class shows a red **LIVE** badge and a **Join now** button on the website and app.

Upload the recording afterwards as a lesson in the related course.

## 7. Announcements

**Announcements → Add new** → title + message (+ optional link). It appears in every student's *Updates* on the website dashboard and in the app (🔔). Use it for new batches, schedule changes, exam alerts and offers.

## 8. Coupons

**Coupons → Add new**:
- **Code** — e.g. `DIWALI25` (stored in capitals, no spaces).
- **Discount %** — 1 to 100. A 100% coupon gives free access.
- **Maximum uses** — leave empty for unlimited.
- **Expires at** — optional.
- **Active** — turn off to stop a coupon immediately.

Students tap **Have a coupon?** on the buy button. The table shows how many times each coupon has been used.

## 9. Students

- **Search** by name, email or phone.
- 🎁 / **Manage access** — see what a student owns, **give free access** to any course / eBook / test series (scholarships, offline payments, complaints), or **remove** access.
- 🛡 / **Make admin** — give another teacher or staff member admin rights. Remove it the same way. Only give admin to people you fully trust — admins can change prices and see all payments.
- 🚫 / **Block** — a blocked student can't use the app; useful if an account is being shared.

## 10. Payments

- **Paid** — successful sales with student, item, coupon, Razorpay payment ID and amount.
- **Started** — the student opened checkout but didn't finish. Useful for follow-ups.
- **Failed** — failed attempts.
- **Export CSV** (website) — for your accountant / GST filing.

**Refunds** are done in the **Razorpay Dashboard → Payments → (payment) → Refund**. After refunding, remove the student's access in **Students → Manage access** if appropriate.

**If a student paid but the course is still locked:** search their payment ID in **Payments**. If it's under *Started*, check the Razorpay dashboard; if the money was received, grant access manually from **Students → Manage access**.

## 11. Inquiries

Messages sent from the website **Contact** page. Use the **WhatsApp** button to reply directly.

## 12. Settings

- **Contact details** (phone, WhatsApp, email, address, social links) — used in the mobile app's *Me* tab.
- **Exam categories** — add, rename or re-order the paths shown on the home page and course filters.
- **Testimonials** — the student quotes on the home page. Only publish real testimonials, with the student's permission.

The website footer and contact page read from `web/src/lib/site.ts` — ask your developer to update it, or edit it on GitHub and Vercel redeploys automatically.

---

## Daily / weekly routine (suggested)

| When | Do |
|---|---|
| Daily | Check **Inquiries** and reply; glance at **Payments** |
| Before each live class | Create it in **Live classes** ≥ 1 day ahead so students get a reminder |
| After each live class | Upload the recording as a lesson |
| Weekly | Post an **Announcement**; add new **Free notes** to attract students |
| Monthly | Export payments CSV; review coupons and switch off expired ones |

## Content protection — what is and isn't possible

- Videos and eBooks are stored privately and streamed through short-lived links, so links copied from the browser stop working after a few hours.
- Downloading is disabled in the player, and students' access is checked on every lesson.
- No platform can fully stop someone filming their screen with another phone. The Terms & Conditions forbid sharing and recording; block accounts that misuse content.

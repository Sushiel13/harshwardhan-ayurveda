# Harshwardhan Ayurveda — Mobile App (Flutter)

One app for **students** and the **owner/admin**. Admins land in the Admin panel after login and can switch to the student view with the 👁 button.

## First-time setup
```bash
cd mobile
bash setup_platforms.sh          # creates android/ & ios/ folders and applies required settings
cp env.example.json env.json      # then fill in your Supabase + website values
flutter run --dart-define-from-file=env.json
```

## Release builds
```bash
flutter build appbundle --release --dart-define-from-file=env.json   # Play Store (.aab)
flutter build ipa --release --dart-define-from-file=env.json         # App Store (needs a Mac + Xcode)
```
See `../docs/SETUP_AND_DEPLOYMENT.md` for signing and store publishing.

## Code map
| Path | What it is |
|---|---|
| `lib/main.dart` | App start, login gate, admin/student switch |
| `lib/services/api.dart` | All database, storage and payment calls |
| `lib/screens/student/` | Home, courses, video player, tests, library, live, profile |
| `lib/screens/admin/` | Dashboard, courses & lessons, tests & questions, eBooks, notes, live, announcements, coupons, students, payments, inquiries |
| `lib/widgets/` | Shared UI (brand emblem, covers, price tags, buy button) |

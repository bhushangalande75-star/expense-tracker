# Expense Tracker — Flutter + FastAPI + Neon

## What's here
- `backend/` — FastAPI API (Python), deploy to Render free tier
- `mobile_app/` — Flutter Android app (luxurious dark/gold theme)
- `.github/workflows/keepalive.yml` — pings the API every 10 min to stop
  Render and Neon from sleeping on the free tier

**Important limitation:** I built and wrote all the code above, but I don't
have a Flutter SDK or Android build toolchain in this sandbox, so I could not
compile/run the Flutter app or the backend here. Treat this as a complete,
ready-to-build starting point — you'll need to build the APK on your own
machine (or via CI) and deploy the backend yourself. Steps below.

## 1. Neon (database)
1. Create a free project at neon.tech.
2. Create a database (e.g. `expense_tracker`).
3. Copy the **pooled connection string** (Dashboard → Connection Details).
4. In Neon project settings, note the auto-suspend delay (default 5 min on
   free tier) — the keep-alive workflow pings more often than this.

## 2. Backend (Render)
1. Push the `backend/` folder to a GitHub repo (or the whole project).
2. On render.com → New → Web Service → connect the repo, root directory
   `backend/`.
3. Render will pick up `render.yaml`, or set manually:
   - Build command: `pip install -r requirements.txt`
   - Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
4. Add environment variable `DATABASE_URL` = your Neon connection string,
   with `postgresql://` (the app converts it to the async driver at runtime).
5. Deploy. On first startup the app creates tables and seeds the default
   categories automatically. Visit `https://<your-app>.onrender.com/health`
   to confirm it's up.

## 3. Keep-alive
1. In your GitHub repo: Settings → Secrets and variables → Actions →
   New repository secret `API_HEALTH_URL` = `https://<your-app>.onrender.com/health`.
2. The workflow in `.github/workflows/keepalive.yml` runs every 10 minutes
   automatically once it's on the default branch — no server of your own
   needed. Each ping hits `/health`, which also runs a tiny query against
   Neon, keeping both awake.
3. Note: GitHub free-tier scheduled Actions can lag by a few minutes and
   pause on completely inactive repos after ~60 days — commit occasionally,
   or switch to a dedicated free pinger like cron-job.org / UptimeRobot
   hitting the same `/health` URL if you want stronger guarantees.

## 4. Flutter app
1. Install Flutter (flutter.dev) and Android Studio / an Android SDK on your
   machine — this step can't be done in this chat.
2. Open `mobile_app/`, run `flutter pub get`.
3. Edit `lib/services/api_service.dart` and set `baseUrl` to your Render URL.
4. Run on a device/emulator: `flutter run`.
5. Build a release APK: `flutter build apk --release` — the file appears at
   `build/app/outputs/flutter-apk/app-release.apk`, installable directly on
   an Android phone.
   - Alternative: set up a GitHub Actions workflow with
     `subosito/flutter-action` to build the APK in CI and attach it to a
     release, if you'd rather not install Flutter locally.

## Categories included by default
Investment, RD / SIP, Groceries, Vegetables, Non-Veg, Petrol / Fuel,
Rent / Maintenance, Electricity / Water / Gas, Mobile / Internet, Dining Out,
Entertainment, Healthcare, Shopping / Clothing, Education, Insurance,
EMI / Loan, Travel, Miscellaneous. Add more anytime via
`POST /categories`.

## API summary
- `GET/POST /expenses`, `PATCH/DELETE /expenses/{id}`
- `GET /categories`, `POST /categories`
- `GET /dashboard/{daily|weekly|monthly|yearly}?start=&end=`
- `GET /health` — keep-alive target

# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Flutter 3.x (Dart) · Material 3 · `http`, `provider`, `fl_chart`, `syncfusion_flutter_gauges`, `shimmer`, `flutter_animate`, `intl`. Backend: Node.js 20 + Express on Vercel, Neon (serverless PostgreSQL). Firmware: Arduino framework via PlatformIO on ESP32 DevKit V1.

## Users

Home gardeners (primary: a university student building and demoing the system, broader: any hobbyist with one or more potted plants or garden beds). They use the app on an Android phone to check on their plants without being physically present, and to override or adjust watering when needed. The audience is Indonesian; labels and copy may mix English and Indonesian.

## Product Purpose

SmartGrow lets a gardener see live soil moisture and air conditions for each plant, trust the system to water automatically when soil gets too dry, and step in manually when needed — all from a phone. Each ESP32 node monitors one plant, runs watering logic locally (so the plant is watered even without WiFi), and syncs readings and events to a backend. The app surfaces that data as gauges, charts, and a watering log, and sends setting changes back to the device within 30 seconds.

Full working title: *SmartGrow: Monitoring Kelembapan Tanah dan Penyiraman Otomatis Berbasis ESP32 dan Flutter*

## Positioning

The control logic runs on the ESP32 itself, not in the cloud — the plant still gets watered if WiFi drops or the server is unreachable. Settings (thresholds, mode, cooldown) are stored in flash on the device, updated from the app within one polling cycle, and survive restarts.

## Operating Context

- **Hardware in the loop:** ESP32 DevKit V1 + capacitive soil moisture sensor v1.2 (GPIO 34) + DHT22 (GPIO 4) + relay (GPIO 26) + 5V mini submersible pump on a separate supply. Optional tank-level sensor on GPIO 32.
- **Sensor calibration:** capacitive sensor reads *higher* when dry; `RAW_DRY`/`RAW_WET` must be calibrated per unit and soil type. Default thresholds: dry 35 %, wet 60 %, max run 30 s, cooldown 30 min.
- **Watering modes:** `auto` (threshold-based with hysteresis and cooldown), `manual` (pump follows app switch, still limited by max run time), `off`.
- **Data flow:** ESP32 → POST /api/readings (every 30 s) → Express API → Neon Postgres → Flutter app polls GET /api/devices every 5 s. Commands travel back in the readings reply.
- **Deployment:** API on Vercel Hobby plan (serverless), database on Neon free tier. Free-tier limits apply; one device posting every 30 s uses ~86 400 invocations/month.
- **Build target:** APK (`flutter build apk --release --dart-define=API_URL=…`) for the university course demo (responsi).

## Capabilities and Constraints

- **8 screens:** Home, Device List, Device Detail, Watering Log, Event Detail, History, Profile/About, Add Device — accessed via a 5-tab bottom navigation bar.
- **Two list → detail flows:** Device List → Device Detail; Watering Log → Event Detail.
- **Live polling:** `DeviceProvider` polls every 5 s; app displays last-known data and surfaces connection errors gracefully.
- **Device onboarding:** user joins the ESP32's WiFi hotspot once, enters home WiFi credentials, then names the device in the app. All boards run identical firmware; only the MAC-derived `hw_id` differs.
- **No user accounts:** write routes (mode, thresholds, pump switch) are protected only by a shared `x-fleet-key` header — acceptable for the coursework demo, not for a real product.
- **Three separate repositories:** `smartgrown_app` (Flutter), `smartgrow-api` (Node.js), `smartgrow-firmware` (PlatformIO).
- **Course requirements:** own API (Modul 1), bottom nav with ≥ 5 pages, ≥ 2 list pages with detail, Profile page, GitHub upload, real ESP32 data at the demo. Deadline: 24 Nov 2026. Responsi: 25–28 Nov 2026.
- **Build order (confirmed):** API → ESP32 firmware → Flutter app skeleton → data layer → controls → polish. Test each step before moving to the next.

## Brand Commitments

Name is **SmartGrow** (display) / `smartgrown_app` (package/repo). Seed color: `#2E9E5B` (green). Material 3. Light and dark theme supported. No other visual commitments locked yet.

## Evidence on Hand

- Full application plan document: `Plan_and_Design/SmartGrow Full Application Plan.docx` — contains complete DB schema, all API endpoint specs, full firmware source, Flutter code samples, deployment steps, and a responsi checklist.
- No screenshots, logo files, or visual assets on disk yet.
- Nothing has been run or tested; all three repositories are yet to be created.

## Product Principles

1. **Local-first reliability.** The plant gets watered whether or not the cloud is reachable; the app is a monitor and override, not the authority.
2. **One device, one plant.** The data model stays flat and explainable — no zones, no groups, no indirection.
3. **Testable in steps.** API works before firmware is written; firmware works before the app is built. Each layer can be verified independently.
4. **Demo-ready simplicity.** Code must be readable and defensible at an oral exam by one student working alone.
5. **Graceful degradation.** Network errors, cold-start latency, and sensor drift are expected; the UI and firmware handle them without crashing.

## Accessibility & Inclusion

No specific accessibility requirements stated. Material 3 defaults (sufficient contrast ratios, touch target sizes) apply.

# Ninja 650 trip companion

Rest-stop Flutter web app: one-tap Google Maps, a rest timer, and baked waypoints. Dark + amber for sunlight. Two trips share the same shell; pick one from **TRIP** at the top right of the app bar.

Flutter app lives at **`ninja/app`**.

| Trip | When | Route |
|------|------|--------|
| **Boise → Home** (default) | Wed 19 – Fri 21 Aug 2026 | Boise → Wells → Primm → Mission Viejo |
| **Ride Home** | 13 Jun 2026 | Morgan Hill → Mission Viejo (I-5 / Grapevine) |

The last selected trip is stored in `shared_preferences` (`selected_trip_id`). Switching trips resets leg, timer, and checklist.

---

## Multi-trip design

Each trip is a `Trip` in [`ninja/app/lib/trips.dart`](ninja/app/lib/trips.dart): stops, companion chip labels, nav button copy, map center, photo, tips. The UI in `lib/main.dart` does not hardcode a route.

| Surface | Behavior |
|---------|----------|
| **TRIP** picker | App bar, top right. Amber chip. Lists `kTrips`. |
| Companion | Current/next leg, giant nav button (≥62px), day or stop stepper, “I am at this stop” chips, rest timer, checklist |
| Map | Dark Carto tiles, pins open a sheet, FAB / buttons open Google Maps |
| Timeline | Stops in order; Boise trip groups by **WED / THU / FRI** |
| Tips | Per-trip fuel / heat / nav notes |

Photos:

- Boise → Home: `assets/images/boise-sunset.jpg` (**full width**, uncropped — `photoFullBleed: true`)
- Ride Home: `assets/images/ninja-bike.jpg` (footer strip)

Fuel preference is **Love’s** whenever a store exists on the line. Caliente (US-93) has no Love’s — still fill.

Tabs keep companion state (timer, checklist, current leg) because that state lives on `TripLogPage`, not inside a tab. Do not put it in `StatefulBuilder`.

Web scrollbars: Flutter web defaults to Android overlay bars that ignore mouse drag. The app uses an interactive `Scrollbar` + Linux scroll behavior. The full-route FAB sits **bottom left** so it does not cover the thumb.

---

## Boise → Home (19–21 Aug 2026)

Three days. Ninja 650. 150-mile rule. Boise / Wells / Ely are **MDT**; Primm and home are **PDT** (one hour earlier). Thursday is the long one (US-93 Great Basin Highway). Skip the Strip: Apex Love’s then straight south to Primm.

### Wed 19 — afternoon to Wells (~250 mi)

| # | Stop | Notes |
|---|------|--------|
| 1 | **Boise, ID** | Afternoon rollout. Full tank. I-84 E. |
| 2 | **Love’s #812 Bliss** | 680 US Hwy 30, I-84 exit 141. ~90 mi. Backup: Jackpot Love’s #891 on US-93. |
| 3 | **Love’s #365 Wells** (night 1) | 157 Hwy 93 S, I-80 exit 352. Fuel + motel. Do not arrive empty. |

### Thu 20 — all day to Primm (~410 mi)

| # | Stop | Notes |
|---|------|--------|
| 4 | **Love’s #691 Ely** | 1701 Great Basin Blvd, US-93 / US-50. ~70 mi. Fill even if the light is off. |
| 5 | **Caliente, NV** lunch | 25 Spring St / US-93. **No Love’s.** 45–60 min. Last real services before I-15. |
| 6 | **Love’s #340 Apex** | 12501 Apex Great Basin Pkwy, I-15 exit 64. Last Love’s before Primm (~45 min). |
| 7 | **Primm, NV** (night 2) | I-15 CA border. Primm Valley / Whiskey Pete’s / Buffalo Bill’s. |

Do not skip Ely or Caliente. Two-lane high desert; services far apart.

### Fri 21 — I-15 home (~230 mi)

| # | Stop | Notes |
|---|------|--------|
| 8 | **Love’s #374 Barstow** | 2974 Lenwood Rd, I-15 exit 178. ~115 mi from Primm. |
| 9 | **Mission Viejo, CA** | I-15 → Cajon → I-215 / I-5. ~140 mi from Barstow. |

Companion progress bar is the three days (Wed Wells / Thu Primm / Fri Home), not nine ticks. Stop chips still match every waypoint.

---

## Ride Home (13 Jun 2026)

Same companion shell. Morgan Hill 8:30 AM → Coalinga (prefer Love’s on I-5) → 24th Street Cafe Bakersfield (60 min lunch) → Castaic Pilot → Mission Viejo. ~381 mi. Photo is the cropped Ninja footer.

---

## Run locally (penguin / Flutter SDK)

App root is nested:

```bash
cd ~/projects/sf/ninja/ninja/app
flutter pub get
flutter run -d chrome
# or:
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

`flutter` must see `pubspec.yaml` in the current directory. New assets need a full restart, not a hot reload.

Chrome on this Crostini guest is Debian Chromium via `chromium-flutter` (see crostini **CHG-016**). Not Island.

```bash
flutter build web
```

`web/index.html` currently hardcodes `<base href="/ninja/">`. Flutter 3.47 `flutter build web --base-href /ninja/` wants `<base href="$FLUTTER_BASE_HREF">` instead.

---

## Layout

```text
ninja/app/
  lib/main.dart      UI (picker, tabs, maps, timer)
  lib/trips.dart     Trip + TripStop data (add new rides here)
  assets/images/     ninja-bike.jpg · boise-sunset.jpg
  web/index.html     base href /ninja/
```

`kTrips` order: Boise first (default), then Ride Home. `tripById` falls back to Boise.

---

## Deploy (GitHub Pages)

Hosted at `https://<user>.github.io/ninja/`.

1. Build from `ninja/app` (or `cd` there in the workflow).
2. Pages workflow needs `pages: write` and `id-token: write`.
3. Keep `<base href="/ninja/">` or the `$FLUTTER_BASE_HREF` placeholder + `--base-href /ninja/`.

---

## Gotchas

**Google Maps one-tap.** `url_launcher` + Directions API (`travelmode=driving`, origin/destination/waypoints). Opens the native Maps app, not a browser tab. Each `Trip.nextLegUrl` / `fullRouteUrl` is built from stop `q` strings.

**State.** Timer, checklist, and current leg live on the parent `State`. Switching **trips** resets them; switching **tabs** does not.

**Road UX.** `#FFB23E` on `#0C0B10`. Nav buttons ≥62px.

**Scrollbar.** Interactive `Scrollbar` on companion / timeline / tips. Mouse + trackpad drag enabled. FAB is `startFloat`.

---

## Add another trip

1. Define a `const Trip(...)` in `lib/trips.dart` (stops, labels, photo, map center, tips).
2. Append it to `kTrips`.
3. Add the photo under `assets/images/` and list it in `pubspec.yaml`.
4. `flutter run -d chrome` (full restart if you added an asset).

Do not put route coordinates back into `main.dart`.

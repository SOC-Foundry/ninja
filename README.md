# 🏍️ Ninja Ephemeral Trip Sites: Engineer's Guide

This repository serves as a blueprint for deploying high-performance, ephemeral Flutter web applications to **GitHub Pages** using **GitHub Actions**. It's optimized for "companion" apps—tools meant to be used on-the-go (e.g., at a motorcycle rest stop).

## 🚀 Deployment Strategy (Step-by-Step)

To deploy this Flutter site to `https://<user>.github.io/<repo>/`, follow these steps:

### 1. Hardcode or Pass the Base Href
Flutter web apps need to know their relative path. Since GitHub project pages are hosted at `/repo-name/`, you MUST specify this during the build or in `index.html`.
- **Method A (Recommended):** Use the `--base-href` flag in your build command:
  ```bash
  flutter build web --base-href /ninja/
  ```
- **Method B (Safeguard):** Ensure `<base href="/ninja/">` is present in `web/index.html`.

### 2. Configure GitHub Actions
Create a `.github/workflows/deploy.yml` in the **root** of your repository. 
- **Critical:** If your Flutter app lives in a subdirectory (like `/app`), you must `cd` into it before running `flutter pub get` and `flutter build`.
- **Permissions:** Ensure the workflow has `pages: write` and `id-token: write` permissions.

### 3. The `index.html` Bootstrap
Standard Flutter `index.html` templates sometimes fail in specific mobile environments or when base paths shift. 
- Use the **Flutter Loader (`flutter.js`)** to initialize the engine.
- Ensure all asset paths are relative or correctly prefixed by the base href.

---

## 🛠️ Technical Gotchas & Fixes

### 📍 Deep Linking to Google Maps
To ensure "one-tap" navigation works flawlessly on both iOS and Android:
- Use the `url_launcher` package.
- Formulate URLs using the Google Maps Directions API:
  `https://www.google.com/maps/dir/?api=1&destination=LAT,LNG&travelmode=driving`
- This forces the native app to open rather than a browser tab.

### 🧩 State Persistence (Tabs)
In a multi-tab companion app, users expect their "rest timer" or "checklist" to persist when switching between the Map and the Timeline.
- **Do NOT** use `StatefulBuilder` inside a tab view for primary state.
- **DO** lift state to the parent `StatefulWidget` class. This ensures that even if the tab's widget tree is rebuilt, the data (leg progress, timers) remains intact.

### 🎨 Design for the Road
- **High Contrast:** Use "Dark Mode" with amber/gold accents (e.g., `#FFB23E`) for visibility in direct sunlight.
- **Tap Targets:** Buttons should be at least `62px` high to allow for gloved or shaky hands at rest stops.

---

## 🔄 Recycling this Site
To reuse this for the next trip:
1. Update `kStops` in `lib/main.dart` with new coordinates and notes.
2. Swap out `assets/images/ninja-bike.jpg`.
3. Update the `base-href` in the workflow and `index.html` if the repo name changes.
4. `git push` — the Actions runner handles the rest.

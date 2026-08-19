# Ninja 650 trip companion

Canonical write-up is the repo-root [README](../README.md). Flutter app: **`app/`**.

Two trips, one shell. **TRIP** picker, top right.

| Trip | When | Route |
|------|------|--------|
| **Boise → Home** (default) | Wed 19 – Fri 21 Aug 2026 | Boise → Wells (Love’s #365) → US-93 → Primm → Mission Viejo |
| **Ride Home** | 13 Jun 2026 | Morgan Hill → Mission Viejo |

Trip data: [`app/lib/trips.dart`](app/lib/trips.dart). UI: [`app/lib/main.dart`](app/lib/main.dart).

```bash
cd app
flutter pub get
flutter run -d chrome
```

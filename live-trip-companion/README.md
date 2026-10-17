# Live Trip Companion (Jac MVP)

AI-powered travel assistant for Sri Lanka — trip planning, Live Trip Mode, recovery engine, budget tracking, and weather intelligence.

## Run (web / mobile preview)

```bash
cd live-trip-companion
jac start main.jac --dev
```

## Run on Android (Capacitor)

```bash
jac setup mobile --platform android
jac start main.jac --client mobile --dev
```

## Demo flow

1. Open the app — sample **Two-Day Galle Getaway** is preloaded.
2. **My Trips** → open the sample trip → **Start Trip**.
3. **Live Trip** → **Simulate missed bus (demo)** → confirm disruption → review recovery → **Accept Changes**.
4. **Budget** → add expense or upload receipt → confirm extraction.
5. **Live Trip** or **TripMate** → simulate rainy weather → review alternatives.

Simulated transport, weather, and OCR results are labelled **DEMO** in the UI.

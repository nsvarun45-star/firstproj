# LensGuard

Smart Contact Lens Cleaning Case — Flutter companion app.

LensGuard pairs with an ESP32-based smart lens case over Bluetooth Low
Energy to monitor case status, track lens wear duration against a safe
limit, watch cleaning-solution turbidity, drive an automated cleaning
cycle, and keep a local history of every session.

> **This build runs on MOCK BLE data.** A scripted simulator
> (`MockBleSimulator` in `lib/services/ble_service.dart`) emits a realistic
> open → wear → close → reopen → clean cycle every 2 seconds so every
> screen and notification can be exercised without real hardware.

## Getting started

```bash
flutter pub get
flutter run
```

Requires Flutter 3.27+ (uses `DropdownButtonFormField.initialValue` and
`WidgetStatePropertyAll`, both recent Material 3 APIs).

### Android setup notes
- `flutter_local_notifications` needs `POST_NOTIFICATIONS` permission on
  Android 13+; the plugin's example AndroidManifest entries should be
  added if not already present in the generated `android/` project after
  `flutter create .` is re-run, or merge them manually.
- `permission_handler` and `vibration` need no manifest changes beyond
  what their READMEs specify for vibration permission (`VIBRATE`).

### iOS setup notes
- Notification permissions are requested via `DarwinInitializationSettings`
  in `NotificationService.initialize()`.
- Real BLE access requires `NSBluetoothAlwaysUsageDescription` in
  `Info.plist` once you swap in real hardware (see below).

## Folder structure

```
lib/
  main.dart                     # App entry point, Riverpod root, theming
  models/                       # Plain data classes (no Flutter/Riverpod deps)
    ble_models.dart             # CaseStatus, CleaningStatus, telemetry snapshot
    history_entry.dart          # Persisted wear/cleaning record
    app_settings.dart           # User preferences
  services/                     # Stateless-ish business logic, no UI
    ble_service.dart            # BLE abstraction + MockBleSimulator
    notification_service.dart   # flutter_local_notifications wrapper
    timer_service.dart          # Wear-duration stopwatch
    history_service.dart        # History persistence (shared_preferences)
    settings_service.dart       # Settings persistence (shared_preferences)
  providers/                    # Riverpod state, one concern per file
    service_providers.dart      # Singleton service instances
    ble_provider.dart           # Connection state + telemetry streams
    wear_timer_provider.dart    # Wear session state machine
    cleaning_provider.dart      # Cleaning countdown + completion
    solution_quality_provider.dart
    case_open_watcher_provider.dart
    settings_provider.dart
    history_provider.dart
  screens/                      # One folder per bottom-nav tab
    root_shell.dart             # NavigationBar + IndexedStack
    home/home_screen.dart
    cleaning/cleaning_screen.dart
    history/history_screen.dart
    settings/settings_screen.dart
  widgets/                      # Shared, reusable UI pieces
    glass_card.dart             # Core glassmorphism container
    animated_background.dart    # Gradient + drifting glow blobs
    case_status_card.dart
    wear_timer_card.dart
    solution_quality_card.dart
    lens_replaced_dialog.dart
    wear_duration_result_card.dart
  theme/
    app_colors.dart
    app_theme.dart
```

## Swapping in a real ESP32

All real-hardware integration points are isolated behind the `BleService`
interface in `lib/services/ble_service.dart`. To connect to real
hardware:

1. Add a new class implementing `BleService` using `flutter_blue_plus`
   (a commented-out skeleton already lives at the bottom of
   `BleServiceImpl` in that file — uncomment and fill in your ESP32's
   actual service/characteristic UUIDs).
2. In `lib/providers/service_providers.dart`, change `bleServiceProvider`
   to return your real implementation instead of `BleServiceImpl()`
   (which currently delegates to `MockBleSimulator`).
3. Feed each incoming BLE notification line straight into the existing
   `parseIncomingData(line, previousTelemetry)` pure function — no
   parsing logic needs to change, since both mock and real paths produce
   the same `LensCaseTelemetry` snapshots.

No provider, screen, or widget code needs to change — they all consume
`telemetryProvider` / `bleConnectionStateProvider`, which are agnostic to
where the data actually comes from.

## Known gaps / follow-ups

- Lottie animation file paths are referenced nowhere yet beyond the
  `assets/animations/` folder placeholder — checkmark/success and
  cleaning-in-progress animations currently use Flutter's built-in
  `CircularProgressIndicator` + `flutter_animate` instead. Drop real
  `.json` Lottie files into `assets/animations/` and wire them in via
  `Lottie.asset(...)` if you want the full Lottie treatment.
- Background/headless BLE handling (when the app is killed) is out of
  scope for this build; only foreground BLE streaming is implemented.
- No automated tests are included yet; `parseIncomingData` and
  `TimerService` are written as pure/isolated logic specifically to make
  unit testing straightforward to add later.

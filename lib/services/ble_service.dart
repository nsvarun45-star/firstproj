// lib/services/ble_service.dart
//
// Owns all communication with the ESP32 over Bluetooth Low Energy.
//
// CURRENT MODE: MOCK. The MockBleSimulator class below generates a
// realistic scripted sequence of packets (case open -> wearing -> case
// closed -> case reopened -> cleaning cycle -> repeat) and feeds them
// through the same stream interface that real BLE notifications would use.
//
// REAL BLE INTEGRATION: Every place that needs to change to talk to a real
// ESP32 via flutter_blue_plus is marked with a "REAL BLE INTEGRATION"
// comment block. The public API (connectDevice, disconnectDevice,
// sendStartCleaning, telemetryStream) is designed to stay identical so
// swapping the mock for the real implementation doesn't require changes
// in providers or UI.

import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ble_models.dart';

enum BleConnectionState { disconnected, connecting, connected }

abstract class BleService {
  Stream<LensCaseTelemetry> get telemetryStream;
  Stream<BleConnectionState> get connectionStateStream;

  Future<void> connectDevice();
  Future<void> disconnectDevice();

  /// Sends the START_CLEANING command to the ESP32 (or mock).
  Future<void> sendStartCleaning();

  void dispose();
}

/// Production implementation entry point. Swap [MockBleSimulator] for a
/// real flutter_blue_plus-backed class implementing the same [BleService]
/// interface when hardware is available.
class BleServiceImpl implements BleService {
  // Internal mock engine. Replace with a real GATT client for production.
  final MockBleSimulator _mock = MockBleSimulator();

  @override
  Stream<LensCaseTelemetry> get telemetryStream => _mock.telemetryStream;

  @override
  Stream<BleConnectionState> get connectionStateStream => _mock.connectionStateStream;

  @override
  Future<void> connectDevice() => _mock.connectDevice();

  @override
  Future<void> disconnectDevice() => _mock.disconnectDevice();

  @override
  Future<void> sendStartCleaning() => _mock.sendStartCleaning();

  @override
  void dispose() => _mock.dispose();

  // REAL BLE INTEGRATION ------------------------------------------------
  // A real implementation would look roughly like this:
  //
  // static const String deviceName = "LensGuard-ESP32";
  // static final Guid serviceUuid = Guid("0000FFE0-0000-1000-8000-00805F9B34FB");
  // static final Guid charUuid = Guid("0000FFE1-0000-1000-8000-00805F9B34FB");
  //
  // BluetoothDevice? _device;
  // BluetoothCharacteristic? _writeChar;
  // StreamSubscription? _notifySub;
  //
  // Future<void> connectDevice() async {
  //   final results = await FlutterBluePlus.scan(
  //     withServices: [serviceUuid],
  //     timeout: const Duration(seconds: 5),
  //   ).toList();
  //   if (results.isEmpty) throw Exception("ESP32 not found");
  //   _device = results.first.device;
  //   await _device!.connect();
  //   final services = await _device!.discoverServices();
  //   final service = services.firstWhere((s) => s.uuid == serviceUuid);
  //   _writeChar = service.characteristics.firstWhere((c) => c.uuid == charUuid);
  //   await _writeChar!.setNotifyValue(true);
  //   _notifySub = _writeChar!.lastValueStream.listen((bytes) {
  //     final line = String.fromCharCodes(bytes);
  //     parseIncomingData(line);
  //   });
  // }
  //
  // Future<void> sendStartCleaning() async {
  //   await _writeChar?.write("START_CLEANING".codeUnits);
  // }
  // -----------------------------------------------------------------------
}

/// Parses a single raw line of ESP32 telemetry (e.g. "Turbidity:1780") and
/// merges it into the previous [LensCaseTelemetry] snapshot. Kept as a
/// standalone pure function so both the mock and real BLE paths can share
/// identical parsing logic, and so it's easy to unit test.
LensCaseTelemetry parseIncomingData(String line, LensCaseTelemetry previous) {
  final packet = RawBlePacket.tryParse(line);
  if (packet == null) return previous;

  switch (packet.key.trim()) {
    case 'Case':
      return previous.copyWith(caseStatus: CaseStatusParsing.fromWire(packet.value));
    case 'Turbidity':
      return previous.copyWith(turbidity: int.tryParse(packet.value.trim()) ?? previous.turbidity);
    case 'Cleaning':
      return previous.copyWith(cleaningStatus: CleaningStatusParsing.fromWire(packet.value));
    case 'Motor':
      return previous.copyWith(motorState: PeripheralStateParsing.fromWire(packet.value));
    case 'Buzzer':
      return previous.copyWith(buzzerState: PeripheralStateParsing.fromWire(packet.value));
    default:
      return previous;
  }
}

/// -----------------------------------------------------------------------
/// MOCK BLE SIMULATOR
/// -----------------------------------------------------------------------
/// Emits a scripted, realistic sequence of packets every ~2 seconds:
///   1. Connecting -> Connected
///   2. Case:OPEN                          (user opens case to take lens out)
///   3. Turbidity readings drift slowly downward over time (solution ages)
///   4. Case:CLOSED                        (user closes case while wearing)
///   5. Case:OPEN                          (user returns to put lens back)
///   6. (App shows "Did you place the lens back?" popup - handled by provider)
///   7. On START_CLEANING command -> Cleaning:CLEANING, Motor:ON
///   8. After 30s -> Motor:OFF, Buzzer:ON, Cleaning:COMPLETE
///   9. Cycle repeats with a fresh, slightly-improved turbidity baseline.
///
/// This gives the UI real state transitions to react to instead of pure
/// random noise, matching how a real ESP32 session would actually unfold.
class MockBleSimulator implements BleService {
  final _telemetryController = StreamController<LensCaseTelemetry>.broadcast();
  final _connectionController = StreamController<BleConnectionState>.broadcast();

  LensCaseTelemetry _state = LensCaseTelemetry.initial();
  Timer? _scriptTimer;
  Timer? _cleaningTimer;
  final Random _rng = Random();

  int _scriptStep = 0;
  int _turbidityBaseline = 1780;
  bool _connected = false;

  @override
  Stream<LensCaseTelemetry> get telemetryStream => _telemetryController.stream;

  @override
  Stream<BleConnectionState> get connectionStateStream => _connectionController.stream;

  @override
  Future<void> connectDevice() async {
    _connectionController.add(BleConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 900));
    _connected = true;
    _connectionController.add(BleConnectionState.connected);
    _emit(_state.copyWith(caseStatus: CaseStatus.closed, turbidity: _turbidityBaseline));
    _startScript();
  }

  @override
  Future<void> disconnectDevice() async {
    _connected = false;
    _scriptTimer?.cancel();
    _cleaningTimer?.cancel();
    _connectionController.add(BleConnectionState.disconnected);
  }

  @override
  Future<void> sendStartCleaning() async {
    if (!_connected) return;
    _cleaningTimer?.cancel();
    _emit(_state.copyWith(
      cleaningStatus: CleaningStatus.cleaning,
      motorState: PeripheralState.on,
      buzzerState: PeripheralState.off,
    ));
    _cleaningTimer = Timer(const Duration(seconds: 30), () {
      // Solution gets a small turbidity improvement after cleaning.
      _turbidityBaseline = (_turbidityBaseline + 60).clamp(1200, 2200);
      _emit(_state.copyWith(
        motorState: PeripheralState.off,
        buzzerState: PeripheralState.on,
        cleaningStatus: CleaningStatus.complete,
        turbidity: _turbidityBaseline,
      ));
      // Buzzer auto turns off shortly after completion, like a real device.
      Timer(const Duration(seconds: 3), () {
        _emit(_state.copyWith(buzzerState: PeripheralState.off));
      });
    });
  }

  /// Drives the scripted open/wear/close/reopen cycle every 2 seconds,
  /// per the spec's "mock BLE data updates every 2 seconds" requirement.
  void _startScript() {
    _scriptTimer?.cancel();
    _scriptTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_connected) return;
      _scriptStep++;

      // Slow turbidity drift to simulate solution aging in real time,
      // independent of the open/close script below.
      final drift = _rng.nextInt(5) - 2; // -2..+2
      final driftedTurbidity = (_state.turbidity + drift).clamp(900, 2200);

      // Loop through a ~10-step scripted scenario, then repeat.
      switch (_scriptStep % 10) {
        case 1:
          _emit(_state.copyWith(caseStatus: CaseStatus.open, turbidity: driftedTurbidity));
          break;
        case 3:
          _emit(_state.copyWith(caseStatus: CaseStatus.closed, turbidity: driftedTurbidity));
          break;
        case 7:
          // User returns; case reopened. Provider layer will surface the
          // "Did you place the lens back?" prompt off of this transition.
          _emit(_state.copyWith(caseStatus: CaseStatus.open, turbidity: driftedTurbidity));
          break;
        default:
          _emit(_state.copyWith(turbidity: driftedTurbidity));
      }
    });
  }

  void _emit(LensCaseTelemetry next) {
    _state = next;
    _telemetryController.add(_state);
  }

  @override
  void dispose() {
    _scriptTimer?.cancel();
    _cleaningTimer?.cancel();
    _telemetryController.close();
    _connectionController.close();
  }
}

class RealBleServiceImpl implements BleService {
  static const String deviceName = "LensGuard-ESP32";
  static final Guid serviceUuid = Guid("0000FFE0-0000-1000-8000-00805F9B34FB");
  static final Guid charUuid = Guid("0000FFE1-0000-1000-8000-00805F9B34FB");

  final _telemetryController = StreamController<LensCaseTelemetry>.broadcast();
  final _connectionController = StreamController<BleConnectionState>.broadcast();

  LensCaseTelemetry _state = LensCaseTelemetry.initial();
  BluetoothDevice? _device;
  BluetoothCharacteristic? _char;
  StreamSubscription? _connectionSub;
  StreamSubscription? _notifySub;

  @override
  Stream<LensCaseTelemetry> get telemetryStream => _telemetryController.stream;

  @override
  Stream<BleConnectionState> get connectionStateStream => _connectionController.stream;

  @override
  Future<void> connectDevice() async {
    _connectionController.add(BleConnectionState.connecting);

    // Request BLE and Location permissions at runtime
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];
    
    // This will show standard runtime permission dialogs on the phone.
    await permissions.request();

    // 1. Scan for the device
    BluetoothDevice? targetDevice;
    final scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName == deviceName || r.advertisementData.advName == deviceName) {
          targetDevice = r.device;
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    
    // Wait until scanning stops (either due to timeout or finding the device)
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    await scanSub.cancel();

    if (targetDevice == null) {
      _connectionController.add(BleConnectionState.disconnected);
      throw Exception("ESP32 BLE device not found");
    }

    _device = targetDevice;

    // Listen to connection state changes
    _connectionSub = _device!.connectionState.listen((state) {
      if (state == BluetoothConnectionState.connected) {
        _connectionController.add(BleConnectionState.connected);
      } else {
        _connectionController.add(BleConnectionState.disconnected);
      }
    });

    // 2. Connect
    await _device!.connect();

    // 3. Discover Services
    final services = await _device!.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid == serviceUuid,
      orElse: () => throw Exception("Service not found"),
    );

    _char = service.characteristics.firstWhere(
      (c) => c.uuid == charUuid,
      orElse: () => throw Exception("Characteristic not found"),
    );

    // 4. Set notify and listen
    await _char!.setNotifyValue(true);
    _notifySub = _char!.lastValueStream.listen((bytes) {
      final line = String.fromCharCodes(bytes);
      final lines = line.split('\n');
      for (var l in lines) {
        if (l.trim().isNotEmpty) {
          _state = parseIncomingData(l, _state);
          _telemetryController.add(_state);
        }
      }
    });
  }

  @override
  Future<void> disconnectDevice() async {
    _notifySub?.cancel();
    _connectionSub?.cancel();
    await _device?.disconnect();
    _connectionController.add(BleConnectionState.disconnected);
  }

  @override
  Future<void> sendStartCleaning() async {
    if (_char != null) {
      await _char!.write("START_CLEANING".codeUnits);
    }
  }

  @override
  void dispose() {
    disconnectDevice();
    _telemetryController.close();
    _connectionController.close();
  }
}

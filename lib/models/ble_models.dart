// lib/models/ble_models.dart
//
// Defines all data types that represent parsed messages coming from the
// ESP32 over BLE. The ESP32 sends plain-text key:value packets, e.g.
//   "Case:OPEN", "Turbidity:1780", "Cleaning:CLEANING", "Motor:ON".
// This file converts those raw strings into strongly-typed enums/values
// that the rest of the app can safely consume.

/// Physical lid state of the lens case, driven by the ESP32's IR sensor.
enum CaseStatus { open, closed, unknown }

/// Current phase of the cleaning cycle, mirrored from the ESP32.
enum CleaningStatus { idle, cleaning, complete }

/// Generic ON/OFF state used for both the vibration motor and the buzzer.
enum PeripheralState { on, off, unknown }

extension CaseStatusParsing on CaseStatus {
  static CaseStatus fromWire(String value) {
    switch (value.trim().toUpperCase()) {
      case 'OPEN':
        return CaseStatus.open;
      case 'CLOSED':
        return CaseStatus.closed;
      default:
        return CaseStatus.unknown;
    }
  }

  bool get isOpen => this == CaseStatus.open;
}

extension CleaningStatusParsing on CleaningStatus {
  static CleaningStatus fromWire(String value) {
    switch (value.trim().toUpperCase()) {
      case 'IDLE':
        return CleaningStatus.idle;
      case 'CLEANING':
        return CleaningStatus.cleaning;
      case 'COMPLETE':
        return CleaningStatus.complete;
      default:
        return CleaningStatus.idle;
    }
  }
}

extension PeripheralStateParsing on PeripheralState {
  static PeripheralState fromWire(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ON':
        return PeripheralState.on;
      case 'OFF':
        return PeripheralState.off;
      default:
        return PeripheralState.unknown;
    }
  }

  bool get isOn => this == PeripheralState.on;
}

/// Immutable snapshot of everything we currently know about the ESP32's
/// state. The [BleService] emits a stream of these as packets arrive and
/// get merged into the previous snapshot (since the ESP32 sends one
/// key:value pair per packet, not a full state dump each time).
class LensCaseTelemetry {
  final CaseStatus caseStatus;
  final int turbidity;
  final CleaningStatus cleaningStatus;
  final PeripheralState motorState;
  final PeripheralState buzzerState;
  final DateTime lastUpdated;

  const LensCaseTelemetry({
    required this.caseStatus,
    required this.turbidity,
    required this.cleaningStatus,
    required this.motorState,
    required this.buzzerState,
    required this.lastUpdated,
  });

  factory LensCaseTelemetry.initial() => LensCaseTelemetry(
        caseStatus: CaseStatus.unknown,
        turbidity: 0,
        cleaningStatus: CleaningStatus.idle,
        motorState: PeripheralState.off,
        buzzerState: PeripheralState.off,
        lastUpdated: DateTime.now(),
      );

  LensCaseTelemetry copyWith({
    CaseStatus? caseStatus,
    int? turbidity,
    CleaningStatus? cleaningStatus,
    PeripheralState? motorState,
    PeripheralState? buzzerState,
  }) {
    return LensCaseTelemetry(
      caseStatus: caseStatus ?? this.caseStatus,
      turbidity: turbidity ?? this.turbidity,
      cleaningStatus: cleaningStatus ?? this.cleaningStatus,
      motorState: motorState ?? this.motorState,
      buzzerState: buzzerState ?? this.buzzerState,
      lastUpdated: DateTime.now(),
    );
  }
}

/// A single raw key:value packet as it arrives off the wire, before being
/// merged into [LensCaseTelemetry]. Keeping this as its own type makes the
/// parsing layer in BleService testable in isolation.
class RawBlePacket {
  final String key;
  final String value;

  const RawBlePacket(this.key, this.value);

  /// Parses a raw line like "Turbidity:1780" into a [RawBlePacket].
  /// Returns null if the line doesn't match the expected "Key:Value" shape.
  static RawBlePacket? tryParse(String line) {
    final parts = line.trim().split(':');
    if (parts.length != 2) return null;
    return RawBlePacket(parts[0], parts[1]);
  }

  @override
  String toString() => '$key:$value';
}

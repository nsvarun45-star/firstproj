// lib/services/timer_service.dart
//
// Encapsulates the stopwatch logic for tracking how long a lens has been
// worn. Kept separate from the provider so the timing math is easy to
// reason about and test independently of Riverpod/state management.

import 'dart:async';

class TimerService {
  DateTime? _startTime;
  Duration _accumulated = Duration.zero;
  Timer? _ticker;
  final _tickController = StreamController<Duration>.broadcast();

  Stream<Duration> get tickStream => _tickController.stream;
  bool get isRunning => _startTime != null;

  /// Starts (or resumes) the wear timer.
  void start() {
    if (isRunning) return;
    _startTime = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickController.add(elapsed);
    });
  }

  /// Stops the timer and returns the final accumulated duration.
  Duration stop() {
    _ticker?.cancel();
    _ticker = null;
    if (_startTime != null) {
      _accumulated += DateTime.now().difference(_startTime!);
      _startTime = null;
    }
    final result = _accumulated;
    _accumulated = Duration.zero;
    return result;
  }

  /// Resets the timer without returning a duration (used when discarding
  /// an in-progress session, e.g. user answers "No" to lens-replaced prompt
  /// — in that case we do NOT reset, we keep running; reset is for explicit
  /// cancellation flows only).
  void reset() {
    _ticker?.cancel();
    _ticker = null;
    _startTime = null;
    _accumulated = Duration.zero;
  }

  /// Current elapsed duration since [start] was called, including any
  /// previously accumulated time.
  Duration get elapsed {
    if (_startTime == null) return _accumulated;
    return _accumulated + DateTime.now().difference(_startTime!);
  }

  void dispose() {
    _ticker?.cancel();
    _tickController.close();
  }
}

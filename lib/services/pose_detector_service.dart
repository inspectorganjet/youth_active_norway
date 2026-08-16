import 'dart:async';
import 'dart:math';

enum WorkoutType { pushups, squats, situps, shadowBoxing }

extension WorkoutTypeExtension on WorkoutType {
  String toNorwegianName() {
    switch (this) {
      case WorkoutType.pushups:
        return 'Armhevinger';
      case WorkoutType.squats:
        return 'Knebøy';
      case WorkoutType.situps:
        return 'Mageøvelse';
      case WorkoutType.shadowBoxing:
        return 'Skyggekamp 🥊';
    }
  }

  String toTypeKey() {
    switch (this) {
      case WorkoutType.pushups:
        return 'pushups';
      case WorkoutType.squats:
        return 'squats';
      case WorkoutType.situps:
        return 'situps';
      case WorkoutType.shadowBoxing:
        return 'shadow_boxing';
    }
  }
}

class PoseDetectorService {
  int _repCount = 0;
  int get repCount => _repCount;

  bool _isDownPosition = false;
  double _currentElbowAngle = 180.0;
  double get currentAngle => _currentElbowAngle;

  StreamController<int>? _repController;
  Stream<int>? get repStream => _repController?.stream;

  Timer? _simulationTimer;

  void startWorkout(WorkoutType type, Function(int reps) onRepCountChanged) {
    _repCount = 0;
    _isDownPosition = false;
    _repController = StreamController<int>.broadcast();

    // Simulerer lokal Google ML Kit / MediaPipe Pose Detection analyse i sanntid
    final Duration interval = type == WorkoutType.shadowBoxing 
        ? const Duration(milliseconds: 350)
        : const Duration(milliseconds: 600);

    _simulationTimer = Timer.periodic(interval, (timer) {
      if (_isDownPosition) {
        _currentElbowAngle = 160.0;
        _isDownPosition = false;
        _repCount++;
        onRepCountChanged(_repCount);
        _repController?.add(_repCount);
      } else {
        _currentElbowAngle = 75.0; // Vinkel under 90 grader = godkjent rep/slag
        _isDownPosition = true;
      }
    });
  }

  void stopWorkout() {
    _simulationTimer?.cancel();
    _repController?.close();
  }

  /// Beregner vinkel mellom tre leddpunkter (f.eks. skulder, albue, håndledd)
  static double calculateAngle({
    required double ax, required double ay,
    required double bx, required double by,
    required double cx, required double cy,
  }) {
    final radians = atan2(cy - by, cx - bx) - atan2(ay - by, ax - bx);
    var angle = (radians * 180.0 / pi).abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }
}

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';
import 'package:motor_animate/src/defaults.dart';

typedef AnimateLoopCallback = void Function(int loopCount);
typedef AnimateSegmentCallback = void Function(
  int segmentIndex,
  double from,
  double to,
  Motion motion,
);

typedef AnimatePhaseSegmentCallback<P> = void Function(
  int segmentIndex,
  P from,
  P to,
  Motion motion,
);

enum _RepeatPhase { min, max }

/// A motor-backed animation controller with flutter_animate-style imperative
/// controls.
///
/// This controller is motion-first: imperative methods use [motion], and
/// sequence playback uses [MotionSequence] phase motions.
class AnimateController extends Animation<double> {
  /// Creates an [AnimateController].
  ///
  /// If [motion] is not provided, it uses the shared package default motion
  /// (the same default exposed via `Animate.defaultMotion`).
  AnimateController({
    required TickerProvider vsync,
    this.lowerBound = 0,
    this.upperBound = 1,
    double value = 0,
    this.animationBehavior = AnimationBehavior.normal,
    Motion? motion,
  })  : assert(lowerBound <= upperBound),
        _defaultMotion = _resolveInitialMotion(motion),
        _motion = BoundedSingleMotionController(
          motion: _resolveInitialMotion(motion),
          vsync: vsync,
          initialValue: value,
          lowerBound: lowerBound,
          upperBound: upperBound,
          behavior: animationBehavior,
        );

  static Motion _resolveInitialMotion(Motion? motion) =>
      motion ?? animateDefaultMotion;

  final BoundedSingleMotionController _motion;

  final double lowerBound;
  final double upperBound;
  final AnimationBehavior animationBehavior;

  Motion _defaultMotion;
  VoidCallback? _cancelPlayback;

  /// The elapsed duration from the currently running motion.
  Duration? get lastElapsedDuration => _motion.lastElapsedDuration;

  /// Current velocity in normalized controller units (per second).
  double get velocity => _motion.velocity;

  /// The default motion used by imperative methods.
  Motion get motion => _defaultMotion;

  set motion(Motion value) {
    _defaultMotion = value;
    _motion.motion = value;
  }

  @override
  double get value => _motion.value;

  set value(double newValue) {
    _cancelPlaybackSession();
    _motion.value = newValue.clamp(lowerBound, upperBound).toDouble();
  }

  @override
  AnimationStatus get status => _motion.status;

  @override
  bool get isAnimating => _motion.isAnimating;

  @override
  void addListener(VoidCallback listener) => _motion.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _motion.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) =>
      _motion.addStatusListener(listener);

  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      _motion.removeStatusListener(listener);

  /// Recreates the ticker with a different [TickerProvider].
  void resync(TickerProvider vsync) => _motion.resync(vsync);

  TickerFuture forward({double? from, double? withVelocity}) {
    _cancelPlaybackSession();
    _motion.motion = _defaultMotion;
    return _motion.forward(from: from, withVelocity: withVelocity);
  }

  TickerFuture reverse({double? from, double? withVelocity}) {
    _cancelPlaybackSession();
    _motion.motion = _defaultMotion;
    return _motion.reverse(from: from, withVelocity: withVelocity);
  }

  TickerFuture animateTo(
    double target, {
    double? from,
    double? withVelocity,
    bool? forward,
    Motion? motion,
  }) {
    _cancelPlaybackSession();
    _motion.motion = motion ?? _defaultMotion;
    final double clampedTarget =
        target.clamp(lowerBound, upperBound).toDouble();
    final double directionStart = from ?? value;
    return _motion.animateTo(
      clampedTarget,
      from: from,
      withVelocity: withVelocity,
      forward: forward ?? clampedTarget >= directionStart,
    );
  }

  TickerFuture animateBack(
    double target, {
    double? from,
    double? withVelocity,
    Motion? motion,
  }) {
    _cancelPlaybackSession();
    _motion.motion = motion ?? _defaultMotion;
    return _motion.animateTo(
      target.clamp(lowerBound, upperBound).toDouble(),
      from: from,
      withVelocity: withVelocity,
      forward: false,
    );
  }

  TickerFuture playSequence<P>(
    MotionSequence<P, double> sequence, {
    P? atPhase,
    void Function(PhaseTransition<P> transition)? onTransition,
    AnimateLoopCallback? onLoop,
    AnimatePhaseSegmentCallback<P>? onSegmentStart,
    AnimatePhaseSegmentCallback<P>? onSegmentComplete,
  }) {
    final List<P> phases = sequence.phases;
    if (phases.isEmpty) {
      return TickerFuture.complete();
    }

    _cancelPlaybackSession();
    _motion.stop(canceled: true);

    int currentIndex = switch (atPhase) {
      final p? => phases.indexOf(p),
      null => phases.indexOf(sequence.initialPhase),
    };
    if (currentIndex < 0) {
      throw ArgumentError('Phase $atPhase not found in provided sequence.');
    }

    value = sequence.valueForPhase(phases[currentIndex]);
    onTransition?.call(PhaseTransition.settled(phases[currentIndex]));
    if (phases.length == 1 && !sequence.loop.isLooping) {
      return TickerFuture.complete();
    }

    bool canceled = false;
    int direction = 1;
    int loopCount = 0;
    int segmentIndex = 0;
    TickerFuture current = TickerFuture.complete();

    void cancelSession() {
      if (canceled) return;
      canceled = true;
    }

    void completeSession() {
      if (canceled) return;
      cancelSession();
      _cancelPlayback = null;
    }

    int? computeNextIndex() {
      final int last = phases.length - 1;
      switch (sequence.loop) {
        case LoopMode.none:
          if (currentIndex >= last) return null;
          return currentIndex + 1;
        case LoopMode.loop:
          if (currentIndex >= last) {
            loopCount += 1;
            onLoop?.call(loopCount);
            return 0;
          }
          return currentIndex + 1;
        case LoopMode.seamless:
          if (currentIndex >= last) {
            loopCount += 1;
            onLoop?.call(loopCount);
            currentIndex = 0;
            value = sequence
                .valueForPhase(phases[currentIndex])
                .clamp(lowerBound, upperBound)
                .toDouble();
            onTransition?.call(PhaseTransition.settled(phases[currentIndex]));
            if (last == 0) return null;
            return currentIndex + 1;
          }
          return currentIndex + 1;
        case LoopMode.pingPong:
          if (currentIndex >= last && direction == 1) {
            direction = -1;
            if (last == 0) return null;
            return currentIndex - 1;
          }
          if (currentIndex <= 0 && direction == -1) {
            direction = 1;
            loopCount += 1;
            onLoop?.call(loopCount);
            if (last == 0) return null;
            return currentIndex + 1;
          }
          return currentIndex + direction;
      }
    }

    void startNextSegment() {
      if (canceled) return;
      final int? nextIndex = computeNextIndex();
      if (nextIndex == null) {
        completeSession();
        return;
      }

      final P from = phases[currentIndex];
      final P to = phases[nextIndex];
      final Motion segmentMotion = sequence.motionForPhase(
        toPhase: to,
        fromPhase: from,
      );
      final double target =
          sequence.valueForPhase(to).clamp(lowerBound, upperBound).toDouble();

      _motion.motion = segmentMotion;
      onSegmentStart?.call(segmentIndex, from, to, segmentMotion);
      if (canceled) return;

      onTransition?.call(PhaseTransition.transitioning(from: from, to: to));
      if (canceled) return;

      current = _motion.animateTo(target, forward: target >= value);
      final int completedSegmentIndex = segmentIndex;
      segmentIndex += 1;

      current.whenCompleteOrCancel(() {
        if (canceled) return;
        currentIndex = nextIndex;
        onSegmentComplete?.call(
          completedSegmentIndex,
          from,
          to,
          segmentMotion,
        );
        if (canceled) return;

        onTransition?.call(PhaseTransition.settled(to));
        if (canceled) return;

        startNextSegment();
      });
    }

    _cancelPlayback = cancelSession;
    startNextSegment();
    return current;
  }

  /// Repeats the animation indefinitely, or for [count] legs if provided.
  ///
  /// One leg corresponds to a single animated segment.
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    int? count,
    Motion? motion,
    AnimateLoopCallback? onLoop,
    AnimateSegmentCallback? onSegmentStart,
    AnimateSegmentCallback? onSegmentComplete,
  }) {
    assert(count == null || count >= 0);
    final double start =
        (min ?? lowerBound).clamp(lowerBound, upperBound).toDouble();
    final double end =
        (max ?? upperBound).clamp(lowerBound, upperBound).toDouble();

    if (count == 0) {
      value = start;
      return TickerFuture.complete();
    }

    if (start == end) {
      value = start;
      return TickerFuture.complete();
    }

    final Motion repeatMotion = motion ?? _defaultMotion;
    final LoopMode loopMode = reverse ? LoopMode.pingPong : LoopMode.seamless;
    final sequence = MotionSequence<_RepeatPhase, double>.states(
      <_RepeatPhase, double>{
        _RepeatPhase.min: start,
        _RepeatPhase.max: end,
      },
      motion: repeatMotion,
      loop: loopMode,
    );

    if (!reverse) {
      value = start;
    }

    int startedSegments = 0;
    int completedSegments = 0;

    return playSequence<_RepeatPhase>(
      sequence,
      atPhase: _RepeatPhase.min,
      onLoop: onLoop,
      onSegmentStart: (index, fromPhase, toPhase, segmentMotion) {
        if (count != null && startedSegments >= count) {
          stop(canceled: true);
          return;
        }
        startedSegments += 1;
        onSegmentStart?.call(
          index,
          sequence.valueForPhase(fromPhase),
          sequence.valueForPhase(toPhase),
          segmentMotion,
        );
      },
      onSegmentComplete: (index, fromPhase, toPhase, segmentMotion) {
        completedSegments += 1;
        onSegmentComplete?.call(
          index,
          sequence.valueForPhase(fromPhase),
          sequence.valueForPhase(toPhase),
          segmentMotion,
        );
        if (count != null && completedSegments >= count) {
          stop(canceled: true);
        }
      },
    );
  }

  TickerFuture stop({bool canceled = true}) {
    _cancelPlaybackSession();
    return _motion.stop(canceled: canceled);
  }

  void reset() {
    _cancelPlaybackSession();
    _motion.value = lowerBound;
  }

  void dispose() {
    _cancelPlaybackSession();
    _motion.dispose();
  }

  void _cancelPlaybackSession() {
    _cancelPlayback?.call();
    _cancelPlayback = null;
  }
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../motor_animate.dart';

/// Provides a common interface for [Animate] and [AnimateList] to attach [Effect] extensions.
mixin AnimateManager<T> {
  T addEffect(Effect effect) => throw (UnimplementedError());
  T addEffects(List<Effect> effects) {
    for (Effect o in effects) {
      addEffect(o);
    }
    return this as T;
  }
}

/// Because [Effect] classes are immutable and may be reused between multiple
/// [Animate] (or [AnimateList]) instances, an [EffectEntry] is created to store
/// values that may be different between instances. For example, due to an
/// `interval` on `AnimateList`, or from inheriting timing parameters.
@immutable
class EffectEntry {
  factory EffectEntry({
    required Effect effect,
    required Duration delay,
    required Motion motion,
    required Animate owner,
  }) {
    final Duration span = _MotionPhase.estimateSpan(motion);
    return EffectEntry._(
      effect: effect,
      delay: delay,
      motion: motion,
      owner: owner,
      span: span,
      phase: _MotionPhase(motion, span),
    );
  }

  const EffectEntry._({
    required this.effect,
    required this.delay,
    required this.motion,
    required this.owner,
    required this.span,
    required _MotionPhase phase,
  }) : _phase = phase;

  /// The delay for this entry.
  final Duration delay;

  /// The motion used by this entry.
  final Motion motion;

  /// The effect associated with this entry.
  final Effect effect;

  /// The [Animate] instance that created this entry. This can be used by effects
  /// to read information about the animation. Effects _should not_ modify
  /// the animation (ex. by calling [Animate.addEffect]).
  final Animate owner;

  /// The resolved time span of this entry's motion.
  final Duration span;
  final _MotionPhase _phase;

  /// The begin time for this entry.
  Duration get begin => delay;

  /// The end time for this entry.
  Duration get end => delay + span;

  /// Applies this entry's motion transform to a normalized value.
  double transform(double t) => _phase.transform(t);

  /// Best-effort resolution of how long this motion takes to settle.
  static Duration estimateSpanFor(Motion motion) =>
      _MotionPhase.estimateSpan(motion);

  /// Builds a sub-animation based on the properties of this entry.
  Animation<double> buildAnimation(
    AnimateController controller, {
    Motion? motion,
  }) {
    final int ttlT = math.max(1, owner.duration.inMicroseconds);
    final int beginT = begin.inMicroseconds;
    final int endT = end.inMicroseconds;
    final _MotionPhase phase = motion == null
        ? _phase
        : _MotionPhase(motion, _MotionPhase.estimateSpan(motion));
    final Curve segmentCurve = _MotionSegmentCurve(phase: phase);
    return CurvedAnimation(
      parent: controller,
      curve: Interval(beginT / ttlT, endT / ttlT, curve: segmentCurve),
    );
  }
}

class _MotionSegmentCurve extends Curve {
  const _MotionSegmentCurve({required this.phase});

  final _MotionPhase phase;

  @override
  double transform(double t) => phase.transform(t);
}

class _MotionPhase {
  _MotionPhase(this.motion, this.span)
      : _simulation = motion.createSimulation(start: 0, end: 1, velocity: 0);

  final Motion motion;
  final Duration span;
  final Simulation _simulation;

  static const Duration _fallback = Duration(milliseconds: 300);
  static const double _maxEstimateSeconds = 30;
  static const double _coarseStepSeconds = 1 / 120;

  double transform(double t) {
    final double clamped = t.clamp(0, 1).toDouble();
    final double seconds =
        span.inMicroseconds / Duration.microsecondsPerSecond * clamped;
    return _simulation.x(seconds);
  }

  static Duration estimateSpan(Motion motion) {
    if (motion case CurvedMotion(:final duration)) return duration;
    if (motion case NoMotion(:final duration)) return duration;
    if (motion case CupertinoMotion(:final duration)) return duration;

    final Simulation simulation =
        motion.createSimulation(start: 0, end: 1, velocity: 0);

    if (simulation.isDone(0)) return Duration.zero;

    double upper = _coarseStepSeconds;
    while (upper <= _maxEstimateSeconds && !simulation.isDone(upper)) {
      upper += _coarseStepSeconds;
    }
    if (upper > _maxEstimateSeconds) {
      return _fallback;
    }

    double lower = (upper - _coarseStepSeconds).clamp(0, upper);
    for (int i = 0; i < 12; i++) {
      final double mid = (lower + upper) / 2;
      if (simulation.isDone(mid)) {
        upper = mid;
      } else {
        lower = mid;
      }
    }

    final int micros = (upper * Duration.microsecondsPerSecond)
        .ceil()
        .clamp(1, _maxEstimateSeconds.toInt() * Duration.microsecondsPerSecond);
    return Duration(microseconds: micros);
  }
}

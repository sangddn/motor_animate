import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';
import '../controllers/animate_controller.dart';

enum _LoopPhase { min, max }

/// Adds a [loop] extension on [AnimateController] identical to [repeat] but
/// adding a `count` parameter specifying how many times to repeat before stopping:
///
///   - `count = null`: the animation loops infinitely
///   - `count = 0`: the animation won't play
///   - `count > 0`: the animation will play `count` times
///
/// If [reverse] is true, one "count" is still considered a single directional leg.
///
/// For example, the following would play forward (fade in) and back (fade out) once, then stop:
///
/// ```
/// Text('Hello World').animate(
///   onPlay: (controller) => controller.loop(
///     reverse: true,
///     count: 2,
///   ),
/// ).fadeIn();
/// ```
extension AnimateControllerLoopExtensions on AnimateController {
  TickerFuture loop({
    int? count,
    bool reverse = false,
    double? min,
    double? max,
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

    if (count == 0 || start == end) {
      value = start;
      return TickerFuture.complete();
    }

    final Motion resolvedMotion = motion ?? this.motion;
    final LoopMode loopMode = reverse ? LoopMode.pingPong : LoopMode.seamless;
    final MotionSequence<_LoopPhase, double> sequence =
        MotionSequence<_LoopPhase, double>.states(
      <_LoopPhase, double>{
        _LoopPhase.min: start,
        _LoopPhase.max: end,
      },
      motion: resolvedMotion,
      loop: loopMode,
    );

    if (!reverse) {
      value = start;
    }

    int startedSegments = 0;
    int completedSegments = 0;

    return playSequence<_LoopPhase>(
      sequence,
      atPhase: _LoopPhase.min,
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
}

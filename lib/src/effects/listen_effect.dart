import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// An effect that calls a [callback] function with its current animation value
/// between [begin] and [end].
///
/// By default, the callback will only be called while this effect is "active"
/// (ie. after delay, and before its motion settles) and will return a value
/// between 0-1 (unless the motion transforms it beyond this range). If [clamp]
/// is set to `false`,
/// the callback will be called on every tick while the enclosing [Animate] is
/// running, and may return values outside its nominal range (ex. it will return a
/// negative value before delay).
///
/// This example will print the current animation value (which matches the value
/// of the preceding fade effect's opacity value):
///
/// ```
/// Text("Hello").animate()
///  .fadeIn(motion: Motion.curved(900.ms, Curves.easeOutExpo))
///  .listen(onValue: (value) => print('current opacity: $value'))
/// ```
///
/// This can easily be used to drive a [ValueNotifier]:
///
/// ```
/// ValueNotifier<double> notifier = ValueNotifier<double>(0);
/// Text("Hello").animate()
///   .fadeIn(delay: 400.ms, motion: Motion.linear(900.ms))
///   .listen(onValue: (value) => notifier.value)
/// ```
///
/// See also: [CustomEffect] and [CallbackEffect].
@immutable
class ListenEffect extends Effect<double> {
  const ListenEffect({
    super.delay,
    super.motion,
    double? begin,
    double? end,
    this.onValue,
    this.onStatus,
    this.clamp = true,
  })  : assert(
          onValue != null || onStatus != null,
          'Either onValue or onStatus must be provided',
        ),
        super(
          begin: begin ?? 0.0, // Should this use "smart" defaults?
          end: end ?? 1.0,
        );

  final ValueChanged<double>? onValue;
  final ValueChanged<AnimationStatus>? onStatus;
  final bool clamp;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimateController controller,
    EffectEntry entry,
  ) {
    // Use a linear motion so we get a normalized 0-1 progression for begin/end interpolation.
    Animation<double> animation = entry.buildAnimation(
      controller,
      motion: Motion.linear(entry.span),
    );
    double prev = 0.0, begin = this.begin ?? 0.0, end = this.end ?? 1.0;
    if (onValue != null) {
      animation.addListener(() {
        double value = animation.value;
        if (!clamp || value != prev) {
          onValue?.call(begin + (end - begin) * entry.transform(value));
          prev = value;
        }
      });
    }
    AnimationStatus prevStatus = animation.status;
    if (onStatus != null) {
      animation.addStatusListener((status) {
        if (status != prevStatus) {
          onStatus?.call(status);
          prevStatus = status;
        }
      });
    }
    return child;
  }
}

/// Adds [ListenEffect] related extensions to [AnimateManager].
extension ListenEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [ListenEffect] that calls a [callback] function with its current animation value
  /// between [begin] and [end].
  T listen({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
    ValueChanged<double>? onValue,
    ValueChanged<AnimationStatus>? onStatus,
    bool clamp = true,
  }) =>
      addEffect(
        ListenEffect(
          delay: delay,
          motion: motion,
          begin: begin,
          end: end,
          onValue: onValue,
          onStatus: onStatus,
          clamp: clamp,
        ),
      );
}

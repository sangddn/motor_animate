import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// An empty effect that all other effects extend.
/// It can be added to [Animate], but has no visual effect.
///
/// Defines the required interface and helper methods for
/// all effect classes. Look at the various effects for examples of how
/// to build new reusable effects. One-off effects can be implemented with
/// [CustomEffect].
@immutable
class Effect<T> {
  /// The specified delay for the effect. If null, will inherit the delay from the
  /// previous effect, or use [Duration.zero] if this is the first effect.
  final Duration? delay;

  /// The specified motion for this effect.
  final Motion? motion;

  /// The begin value for the effect. If null, effects should use a reasonable
  /// default value when appropriate.
  final T? begin;

  /// The end value for the effect. If null, effects should use a reasonable
  /// default value when appropriate.
  final T? end;

  const Effect({
    this.delay,
    this.motion,
    this.begin,
    this.end,
  });

  /// Builds the widgets that implement the effect on the target [child],
  /// based on the provided [AnimateController] and [EffectEntry].
  Widget build(
    BuildContext context,
    Widget child,
    AnimateController controller,
    EffectEntry entry,
  ) {
    return child;
  }

  /// Returns an animation based on the controller, entry, and begin/end values.
  Animation<T> buildAnimation(AnimateController controller, EffectEntry entry) {
    return entry
        .buildAnimation(controller)
        .drive(Tween<T>(begin: begin, end: end));
  }

  /// Returns a ratio corresponding to the beginning of the specified entry.
  double getBeginRatio(AnimateController controller, EffectEntry entry) {
    int ms = entry.owner.duration.inMilliseconds;
    return ms == 0 ? 0 : entry.begin.inMilliseconds / ms;
  }

  /// Returns a ratio corresponding to the end of the specified entry.
  double getEndRatio(AnimateController controller, EffectEntry entry) {
    int ms = entry.owner.duration.inMilliseconds;
    return ms == 0 ? 0 : entry.end.inMilliseconds / ms;
  }

  /// Check if the animation is currently running / active.
  bool isAnimationActive(Animation animation) {
    AnimationStatus status = animation.status;
    return status == AnimationStatus.forward ||
        status == AnimationStatus.reverse;
  }

  /// Returns an optimized [AnimatedBuilder] that doesn't
  /// rebuild if the value hasn't changed.
  AnimatedBuilder getOptimizedBuilder<U>({
    required ValueListenable<U> animation,
    Widget? child,
    required TransitionBuilder builder,
  }) {
    U? value;
    Widget? widget;
    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, _) {
        if (animation.value != value) widget = null;
        value = animation.value;
        return widget = widget ?? builder(ctx, child);
      },
    );
  }

  /// Returns an [AnimatedBuilder] that rebuilds when the
  /// boolean value returned by the `toggle` function changes.
  AnimatedBuilder getToggleBuilder({
    required ValueListenable<double> animation,
    required Widget child,
    required bool Function() toggle,
    required ToggleEffectBuilder builder,
  }) {
    ValueNotifier<bool> notifier = ValueNotifier<bool>(toggle());
    animation.addListener(() => notifier.value = toggle());
    return AnimatedBuilder(
      animation: notifier,
      builder: (ctx, _) => builder(ctx, notifier.value, child),
    );
  }
}

/// Adds [Effect] related extensions to [AnimateManager].
extension EffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds an [Effect] which has no visual effect. Occasionally useful for
  /// setting inheritable `delay` and `motion` values.
  T effect({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
  }) =>
      addEffect(
        Effect(
          delay: delay,
          motion: motion,
          begin: begin,
          end: end,
        ),
      );
}

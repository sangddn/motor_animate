import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// An effect that allows you to toggle the behavior of a [builder] function at a certain
/// point in time.
///
/// ```
/// Animate().toggle(motion: Motion.linear(500.ms), builder: (_, value, __) =>
///   Text('${value ? "Before Delay" : "After Delay"}'))
/// ```
///
/// This is also useful for triggering animation in "Animated" widgets.
///
/// ```
/// foo.animate().toggle(motion: Motion.linear(500.ms), builder: (_, value, child) =>
///   AnimatedOpacity(opacity: value ? 0 : 1, child: child))
/// ```
///
/// The child of `Animate` is passed through to the builder in the `child` param
/// (possibly already wrapped by prior effects).
@immutable
class ToggleEffect extends Effect<void> {
  const ToggleEffect({
    super.delay,
    super.motion,
    required this.builder,
  });

  final ToggleEffectBuilder builder;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimateController controller,
    EffectEntry entry,
  ) {
    double ratio = getEndRatio(controller, entry);
    return getToggleBuilder(
      animation: controller,
      child: child,
      toggle: () => controller.value < ratio,
      builder: builder,
    );
  }
}

/// Adds [ToggleEffect] related extensions to [AnimateManager].
extension ToggleEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [ToggleEffect] that allows you to toggle the behavior of a [builder] function at a certain
  /// point in time.
  T toggle({
    Duration? delay,
    Motion? motion,
    required ToggleEffectBuilder builder,
  }) =>
      addEffect(
        ToggleEffect(delay: delay, motion: motion, builder: builder),
      );
}

typedef ToggleEffectBuilder = Widget Function(
    BuildContext context, bool value, Widget child);

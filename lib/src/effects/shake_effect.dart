import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// Effect that shakes the target, using translation, rotation, or both (via [Transform]).
///
/// The [hz] parameter indicates approximately how many times to repeat the shake
/// per second. It defaults to `8`.
///
/// Specify [rotation], [offset], or both to indicate the type and strength of the
/// shaking. Defaults to `rotation=pi/36, offset=Offset.zero`, which results in
/// a light rotational shake.
///
/// This example would shake left and right slowly by 10px:
///
/// ```
/// Text("Hello").animate()
///   .shake(hz: 3, offset: Offset(10, 0))
/// ```
///
/// There are also `shakeX` and `shakeY` shortcut extension methods.
@immutable
class ShakeEffect extends Effect<double> {
  static const double defaultHz = 8;
  static const double defaultRotation = pi / 36;
  static const double defaultMove = 5;

  const ShakeEffect({
    super.delay,
    super.motion,
    double? hz,
    Offset? offset,
    double? rotation,
  })  : rotation = rotation ?? defaultRotation,
        hz = hz ?? defaultHz,
        offset = offset ?? Offset.zero,
        super(begin: 0, end: 1);

  final Offset offset;
  final double rotation;
  final double hz;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimateController controller,
    EffectEntry entry,
  ) {
    final bool shouldRotate = rotation != 0;
    final bool shouldTranslate = offset != Offset.zero;
    if (!shouldRotate && !shouldTranslate) return child;

    final Animation<double> animation = buildAnimation(controller, entry);
    final int count = (entry.span.inMilliseconds / 1000 * hz).round();

    return getOptimizedBuilder<double>(
      animation: animation,
      builder: (_, __) {
        double value = sin(animation.value * count * pi * 2);
        Widget widget = child;
        if (shouldRotate) {
          widget = Transform.rotate(angle: rotation * value, child: widget);
        }
        if (shouldTranslate) {
          widget = Transform.translate(offset: offset * value, child: widget);
        }
        return widget;
      },
    );
  }
}

/// Adds [ShakeEffect] related extensions to [AnimateManager].
extension ShakeEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [ShakeEffect] that shakes the target, using translation, rotation,
  /// or both (via [Transform]).
  T shake({
    Duration? delay,
    Motion? motion,
    double? hz,
    Offset? offset,
    double? rotation,
  }) =>
      addEffect(
        ShakeEffect(
          delay: delay,
          motion: motion,
          hz: hz,
          offset: offset,
          rotation: rotation,
        ),
      );

  /// Adds a [ShakeEffect] that shakes the target horizontally (via [Transform]).
  T shakeX({
    Duration? delay,
    Motion? motion,
    double? hz,
    double? amount,
  }) =>
      addEffect(
        ShakeEffect(
          delay: delay,
          motion: motion,
          hz: hz,
          offset: Offset(amount ?? ShakeEffect.defaultMove, 0),
          rotation: 0,
        ),
      );

  /// Adds a [ShakeEffect] that shakes the target vertically (via [Transform]).
  T shakeY({
    Duration? delay,
    Motion? motion,
    double? hz,
    double? amount,
  }) =>
      addEffect(
        ShakeEffect(
          delay: delay,
          motion: motion,
          hz: hz,
          offset: Offset(0, amount ?? ShakeEffect.defaultMove),
          rotation: 0,
        ),
      );
}

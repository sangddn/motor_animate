import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// An effect that sizes the target as a factor of its child's size
/// (via [Align.widthFactor] and [Align.heightFactor], optionally clipped).
/// Defaults to `begin=Offset(0, 0), end=Offset(1, 1)`.
@immutable
class SizeEffect extends Effect<Offset> {
  static const Offset neutralValue = Offset(neutralFactor, neutralFactor);
  static const Offset defaultValue = Offset(defaultFactor, defaultFactor);

  static const double neutralFactor = 1.0;
  static const double defaultFactor = 0.0;
  static const Alignment defaultAlignment = Alignment.center;
  static const Clip defaultClip = Clip.none;

  const SizeEffect({
    super.delay,
    super.motion,
    Offset? begin,
    Offset? end,
    Alignment? alignment,
    Clip? clip,
  })  : alignment = alignment ?? defaultAlignment,
        clip = clip ?? defaultClip,
        super(
          begin: begin ?? (end == null ? defaultValue : neutralValue),
          end: end ?? neutralValue,
        );

  final Alignment alignment;
  final Clip clip;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimateController controller,
    EffectEntry entry,
  ) {
    Animation<Offset> animation = buildAnimation(controller, entry);
    return getOptimizedBuilder<Offset>(
      animation: animation,
      builder: (_, __) {
        Widget widget = Align(
          alignment: alignment,
          widthFactor: animation.value.dx,
          heightFactor: animation.value.dy,
          child: child,
        );
        if (clip != Clip.none) {
          widget = ClipRect(clipBehavior: clip, child: widget);
        }
        return widget;
      },
    );
  }
}

/// Adds [SizeEffect] related extensions to [AnimateManager].
extension SizeEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [SizeEffect] that sizes the target as a factor of its child.
  T size({
    Duration? delay,
    Motion? motion,
    Offset? begin,
    Offset? end,
    Alignment? alignment,
    Clip? clip,
  }) =>
      addEffect(
        SizeEffect(
          delay: delay,
          motion: motion,
          begin: begin,
          end: end,
          alignment: alignment,
          clip: clip,
        ),
      );

  /// Adds a [SizeEffect] that sizes the target horizontally as a factor
  /// of its child.
  T sizeX({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
    Alignment? alignment,
    Clip? clip,
  }) {
    begin ??= end == null ? SizeEffect.defaultFactor : SizeEffect.neutralFactor;
    end ??= SizeEffect.neutralFactor;
    return addEffect(
      SizeEffect(
        delay: delay,
        motion: motion,
        begin: SizeEffect.neutralValue.copyWith(dx: begin),
        end: SizeEffect.neutralValue.copyWith(dx: end),
        alignment: alignment,
        clip: clip,
      ),
    );
  }

  /// Adds a [SizeEffect] that sizes the target vertically as a factor
  /// of its child.
  T sizeY({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
    Alignment? alignment,
    Clip? clip,
  }) {
    begin ??= end == null ? SizeEffect.defaultFactor : SizeEffect.neutralFactor;
    end ??= SizeEffect.neutralFactor;
    return addEffect(
      SizeEffect(
        delay: delay,
        motion: motion,
        begin: SizeEffect.neutralValue.copyWith(dy: begin),
        end: SizeEffect.neutralValue.copyWith(dy: end),
        alignment: alignment,
        clip: clip,
      ),
    );
  }

  /// Adds a [SizeEffect] that sizes the target uniformly as a factor
  /// of its child.
  T sizeXY({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
    Alignment? alignment,
    Clip? clip,
  }) {
    begin ??= end == null ? SizeEffect.defaultFactor : SizeEffect.neutralFactor;
    end ??= SizeEffect.neutralFactor;
    return addEffect(
      SizeEffect(
        delay: delay,
        motion: motion,
        begin: Offset(begin, begin),
        end: Offset(end, end),
        alignment: alignment,
        clip: clip,
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// An effect that scales the target between the specified [begin] and [end]
/// offset values (via [Transform.scale]).
/// Defaults to `begin=Offset(0,0), end=Offset(1,1)`.
@immutable
class ScaleEffect extends Effect<Offset> {
  static const Offset neutralValue = Offset(neutralScale, neutralScale);
  static const Offset defaultValue = Offset(defaultScale, defaultScale);

  static const double neutralScale = 1.0;
  static const double defaultScale = 0;
  static const double minScale = 0.000001;
  static const bool defaultTransformHitTests = true;

  const ScaleEffect({
    super.delay,
    super.motion,
    Offset? begin,
    Offset? end,
    this.alignment,
    bool? transformHitTests,
  })  : transformHitTests = transformHitTests ?? defaultTransformHitTests,
        super(
          begin: begin ?? (end == null ? defaultValue : neutralValue),
          end: end ?? neutralValue,
        );

  final Alignment? alignment;
  final bool transformHitTests;

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
        return Transform.scale(
          scaleX: _normalizeScale(animation.value.dx),
          scaleY: _normalizeScale(animation.value.dy),
          alignment: alignment ?? Alignment.center,
          transformHitTests: transformHitTests,
          child: child,
        );
      },
    );
  }

  double _normalizeScale(double scale) {
    // addresses an issue with zero value scales:
    // https://github.com/gskinner/flutter_animate/issues/79
    return scale < minScale ? minScale : scale;
  }
}

/// Adds [ScaleEffect] related extensions to [AnimateManager].
extension ScaleEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [ScaleEffect] that scales the target between
  /// the specified [begin] and [end] offset values (via [Transform.scale]).
  T scale({
    Duration? delay,
    Motion? motion,
    Offset? begin,
    Offset? end,
    Alignment? alignment,
    bool? transformHitTests,
  }) =>
      addEffect(
        ScaleEffect(
          delay: delay,
          motion: motion,
          begin: begin,
          end: end,
          alignment: alignment,
          transformHitTests: transformHitTests,
        ),
      );

  /// Adds a [ScaleEffect] that scales the target horizontally between
  /// the specified [begin] and [end] values (via [Transform.scale]).
  T scaleX({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
    Alignment? alignment,
    bool? transformHitTests,
  }) {
    begin ??=
        (end == null ? ScaleEffect.defaultScale : ScaleEffect.neutralScale);
    end ??= ScaleEffect.neutralScale;
    return addEffect(
      ScaleEffect(
        delay: delay,
        motion: motion,
        begin: ScaleEffect.neutralValue.copyWith(dx: begin),
        end: ScaleEffect.neutralValue.copyWith(dx: end),
        alignment: alignment,
        transformHitTests: transformHitTests,
      ),
    );
  }

  /// Adds a [ScaleEffect] that scales the target vertically between
  /// the specified [begin] and [end] values (via [Transform.scale]).
  T scaleY({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
    Alignment? alignment,
    bool? transformHitTests,
  }) {
    begin ??=
        (end == null ? ScaleEffect.defaultScale : ScaleEffect.neutralScale);
    end ??= ScaleEffect.neutralScale;
    return addEffect(
      ScaleEffect(
        delay: delay,
        motion: motion,
        begin: ScaleEffect.neutralValue.copyWith(dy: begin),
        end: ScaleEffect.neutralValue.copyWith(dy: end),
        alignment: alignment,
        transformHitTests: transformHitTests,
      ),
    );
  }

  /// Adds a [ScaleEffect] that scales the target uniformly between
  /// the specified [begin] and [end] values (via [Transform.scale]).
  T scaleXY({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
    Alignment? alignment,
    bool? transformHitTests,
  }) {
    begin ??=
        (end == null ? ScaleEffect.defaultScale : ScaleEffect.neutralScale);
    end ??= ScaleEffect.neutralScale;
    return addEffect(
      ScaleEffect(
        delay: delay,
        motion: motion,
        begin: Offset(begin, begin),
        end: Offset(end, end),
        alignment: alignment,
        transformHitTests: transformHitTests,
      ),
    );
  }
}

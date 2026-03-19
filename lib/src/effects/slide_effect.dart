import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// An effect that moves the target based on a fraction of its size
/// per the specified [begin] and [end] offsets (via [SlideTransition]).
/// Defaults to `begin=Offset(0, -0.5), end=Offset.zero`
/// (slide down from half its height).
///
/// See also: [SlideAbsEffect] for pixel offsets.
@immutable
class SlideEffect extends Effect<Offset> {
  static const Offset neutralValue = Offset(neutralSlide, neutralSlide);
  static const Offset defaultValue = Offset(neutralSlide, defaultSlide);

  static const double neutralSlide = 0.0;
  static const double defaultSlide = -0.5;

  const SlideEffect({
    super.delay,
    super.motion,
    Offset? begin,
    Offset? end,
  }) : super(
          begin: begin ?? (end == null ? defaultValue : neutralValue),
          end: end ?? neutralValue,
        );

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimateController controller,
    EffectEntry entry,
  ) {
    return SlideTransition(
      position: buildAnimation(controller, entry),
      child: child,
    );
  }
}

/// An effect that moves the target between the specified [begin] and [end] offsets
/// in absolute pixels (via [Transform.translate]).
/// Defaults to `begin=Offset(0, -16), end=Offset.zero`.
@immutable
class SlideAbsEffect extends Effect<Offset> {
  static const Offset neutralValue = Offset(neutralSlide, neutralSlide);
  static const Offset defaultValue = Offset(neutralSlide, defaultSlide);

  static const double neutralSlide = 0.0;
  static const double defaultSlide = -16.0;
  static const bool defaultTransformHitTests = true;

  const SlideAbsEffect({
    super.delay,
    super.motion,
    Offset? begin,
    Offset? end,
    bool? transformHitTests,
  })  : transformHitTests = transformHitTests ?? defaultTransformHitTests,
        super(
          begin: begin ?? (end == null ? defaultValue : neutralValue),
          end: end ?? neutralValue,
        );

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
        return Transform.translate(
          offset: animation.value,
          transformHitTests: transformHitTests,
          child: child,
        );
      },
    );
  }
}

/// Adds [SlideEffect] related extensions to [AnimateManager].
extension SlideEffectExtensions<T extends AnimateManager<T>> on T {
  /// Adds a [SlideEffect] that moves the target based on a fraction of its size
  /// per the specified [begin] and [end] offsets (via [SlideTransition]).
  T slide({
    Duration? delay,
    Motion? motion,
    Offset? begin,
    Offset? end,
  }) =>
      addEffect(
        SlideEffect(
          delay: delay,
          motion: motion,
          begin: begin,
          end: end,
        ),
      );

  /// Adds a [SlideEffect] that moves the target horizontally based on a fraction of its size
  /// per the specified [begin] and [end] values (via [SlideTransition]).
  T slideX({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
  }) {
    begin ??= end == null ? SlideEffect.defaultSlide : SlideEffect.neutralSlide;
    end ??= SlideEffect.neutralSlide;
    return addEffect(
      SlideEffect(
        delay: delay,
        motion: motion,
        begin: SlideEffect.neutralValue.copyWith(dx: begin),
        end: SlideEffect.neutralValue.copyWith(dx: end),
      ),
    );
  }

  /// Adds a [SlideEffect] that moves the target vertically based on a fraction of its size
  /// per the specified [begin] and [end] values (via [SlideTransition]).
  T slideY({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
  }) {
    begin ??= end == null ? SlideEffect.defaultSlide : SlideEffect.neutralSlide;
    end ??= SlideEffect.neutralSlide;
    return addEffect(
      SlideEffect(
        delay: delay,
        motion: motion,
        begin: SlideEffect.neutralValue.copyWith(dy: begin),
        end: SlideEffect.neutralValue.copyWith(dy: end),
      ),
    );
  }

  /// Adds a [SlideAbsEffect] that moves the target between the specified [begin]
  /// and [end] absolute offsets (via [Transform.translate]).
  T slideAbs({
    Duration? delay,
    Motion? motion,
    Offset? begin,
    Offset? end,
    bool? transformHitTests,
  }) =>
      addEffect(
        SlideAbsEffect(
          delay: delay,
          motion: motion,
          begin: begin,
          end: end,
          transformHitTests: transformHitTests,
        ),
      );

  /// Adds a [SlideAbsEffect] that moves the target horizontally by absolute pixel
  /// values (via [Transform.translate]).
  T slideXAbs({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
    bool? transformHitTests,
  }) {
    begin ??= end == null ? SlideAbsEffect.defaultSlide : SlideAbsEffect.neutralSlide;
    end ??= SlideAbsEffect.neutralSlide;
    return addEffect(
      SlideAbsEffect(
        delay: delay,
        motion: motion,
        begin: SlideAbsEffect.neutralValue.copyWith(dx: begin),
        end: SlideAbsEffect.neutralValue.copyWith(dx: end),
        transformHitTests: transformHitTests,
      ),
    );
  }

  /// Adds a [SlideAbsEffect] that moves the target vertically by absolute pixel
  /// values (via [Transform.translate]).
  T slideYAbs({
    Duration? delay,
    Motion? motion,
    double? begin,
    double? end,
    bool? transformHitTests,
  }) {
    begin ??= end == null ? SlideAbsEffect.defaultSlide : SlideAbsEffect.neutralSlide;
    end ??= SlideAbsEffect.neutralSlide;
    return addEffect(
      SlideAbsEffect(
        delay: delay,
        motion: motion,
        begin: SlideAbsEffect.neutralValue.copyWith(dy: begin),
        end: SlideAbsEffect.neutralValue.copyWith(dy: end),
        transformHitTests: transformHitTests,
      ),
    );
  }

  // Note: there is no slideXY because diagonal movement isn't a significant use case.
}

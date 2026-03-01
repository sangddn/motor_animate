import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// An effect that animates a [Color] between [begin] and [end], composited with
/// the target using [blendMode] (via [ColorFiltered]). A color value of `null`
/// will be interpreted as a fully transparent version of the other color.
/// Defaults to `begin=null, end=Color(0x800099FF)`.
///
/// [blendMode] defaults to [BlendMode.color].
/// Note that most blend modes in Flutter (including `color`)
/// do not preserve the alpha channel correctly. See [BlendMode.srcATop] or
/// [BlendMode.srcIn] for options that do maintain alpha.
///
/// The following example animates from red to blue with a `multiply` blend:
///
/// ```
/// Image.asset('assets/rainbow.jpg').animate()
///   .color(begin: Colors.red, end: Colors.blue, blendMode: BlendMode.multiply)
/// ```
///
/// See also: [TintEffect], which provides a simpler interface for single color
/// tints.
@immutable
class ColorEffect extends Effect<Color?> {
  static const Color? neutralValue = null;
  static const Color defaultValue = Color(0x800099FF);
  static const BlendMode defaultBlendMode = BlendMode.color;
  static const Color _transparent = Color(0x00000000);

  const ColorEffect({
    super.delay,
    super.motion,
    Color? begin,
    Color? end,
    this.blendMode,
  }) : super(
          begin: begin ?? neutralValue,
          end: end ?? (begin == null ? defaultValue : neutralValue),
        );

  final BlendMode? blendMode;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimateController controller,
    EffectEntry entry,
  ) {
    Animation<double> animation = entry.buildAnimation(controller);
    final startColor = begin;
    final endColor = end;
    final startLab =
        startColor == null ? null : _OkLabColor.fromColor(startColor);
    final endLab = endColor == null ? null : _OkLabColor.fromColor(endColor);

    return getOptimizedBuilder<double>(
      animation: animation,
      builder: (_, __) {
        Color color = _lerpColorOkLab(
              startColor,
              endColor,
              animation.value,
              startLab: startLab,
              endLab: endLab,
            ) ??
            _transparent;
        return ColorFiltered(
          colorFilter: ColorFilter.mode(color, blendMode ?? defaultBlendMode),
          child: child,
        );
      },
    );
  }
}

/// Adds [ColorEffect] related extensions to [AnimateManager].
extension ColorEffectExtension<T extends AnimateManager<T>> on T {
  /// Adds a [ColorEffect] that animates a [Color] between [begin] and [end], composited with
  /// the target using [blendMode] (via [ColorFiltered]). A color value of `null`
  /// will be interpreted as a fully transparent version of the other color.
  T color({
    Duration? delay,
    Motion? motion,
    Color? begin,
    Color? end,
    BlendMode? blendMode,
  }) =>
      addEffect(
        ColorEffect(
          delay: delay,
          motion: motion,
          begin: begin,
          end: end,
          blendMode: blendMode,
        ),
      );
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

Color? _lerpColorOkLab(
  Color? a,
  Color? b,
  double t, {
  _OkLabColor? startLab,
  _OkLabColor? endLab,
}) {
  if (a == null && b == null) return null;

  if (a == null) {
    final end = b!;
    final transparentEnd = end.withValues(alpha: 0.0);
    return _lerpColorOkLabNonNull(
      transparentEnd,
      end,
      t,
      startLab: startLab ?? endLab ?? _OkLabColor.fromColor(transparentEnd),
      endLab: endLab ?? _OkLabColor.fromColor(end),
    );
  }

  if (b == null) {
    final start = a;
    final transparentStart = start.withValues(alpha: 0.0);
    return _lerpColorOkLabNonNull(
      start,
      transparentStart,
      t,
      startLab: startLab ?? _OkLabColor.fromColor(start),
      endLab: endLab ?? startLab ?? _OkLabColor.fromColor(transparentStart),
    );
  }

  return _lerpColorOkLabNonNull(
    a,
    b,
    t,
    startLab: startLab ?? _OkLabColor.fromColor(a),
    endLab: endLab ?? _OkLabColor.fromColor(b),
  );
}

Color _lerpColorOkLabNonNull(
  Color a,
  Color b,
  double t, {
  required _OkLabColor startLab,
  required _OkLabColor endLab,
}) {
  if (t <= 0) return a;
  if (t >= 1) return b;

  final interpolated = _OkLabColor(
    _lerpDouble(startLab.l, endLab.l, t),
    _lerpDouble(startLab.a, endLab.a, t),
    _lerpDouble(startLab.b, endLab.b, t),
  );

  final alpha = _lerpDouble(a.a, b.a, t).clamp(0.0, 1.0);
  return interpolated.toColor(alpha);
}

double _srgbToLinear(double channel) {
  if (channel <= 0.04045) return channel / 12.92;
  return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _linearToSrgb(double channel) {
  if (channel <= 0.0031308) return channel * 12.92;
  return 1.055 * math.pow(channel, 1 / 2.4).toDouble() - 0.055;
}

double _cuberoot(double value) => value < 0
    ? -math.pow(-value, 1 / 3).toDouble()
    : math.pow(value, 1 / 3).toDouble();

@immutable
class _OkLabColor {
  const _OkLabColor(this.l, this.a, this.b);

  factory _OkLabColor.fromColor(Color color) {
    final r = _srgbToLinear(color.r);
    final g = _srgbToLinear(color.g);
    final b = _srgbToLinear(color.b);

    final l = _cuberoot(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    final m = _cuberoot(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    final s = _cuberoot(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);

    return _OkLabColor(
      0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    );
  }

  final double l;
  final double a;
  final double b;

  Color toColor(double alpha) {
    final l = this.l + 0.3963377774 * a + 0.2158037573 * b;
    final m = this.l - 0.1055613458 * a - 0.0638541728 * b;
    final s = this.l - 0.0894841775 * a - 1.2914855480 * b;

    final linearR = 4.0767416621 * l * l * l -
        3.3077115913 * m * m * m +
        0.2309699292 * s * s * s;
    final linearG = -1.2684380046 * l * l * l +
        2.6097574011 * m * m * m -
        0.3413193965 * s * s * s;
    final linearB = -0.0041960863 * l * l * l -
        0.7034186147 * m * m * m +
        1.7076147010 * s * s * s;

    return Color.fromARGB(
      (_clamp01(alpha) * 255).round(),
      (_clamp01(_linearToSrgb(linearR)) * 255).round(),
      (_clamp01(_linearToSrgb(linearG)) * 255).round(),
      (_clamp01(_linearToSrgb(linearB)) * 255).round(),
    );
  }
}

double _clamp01(double value) => value.clamp(0.0, 1.0);

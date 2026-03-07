import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// Maps a [ScrollPosition] to a normalized animation value.
typedef ScrollPositionValueGetter = double Function(ScrollPosition value);

/// Drives an [Animate] animation from a [ScrollPosition].
///
/// The supplied [valueGetter] should derive a `0..1` animation value from the
/// current [scrollPosition].
class ScrollPositionAdapter extends Adapter {
  ScrollPositionAdapter(
    this.scrollPosition, {
    required this.valueGetter,
    super.animated,
    super.direction,
  });

  /// Creates a [ScrollPositionAdapter] from the nearest [Scrollable].
  static ScrollPositionAdapter of(
    BuildContext context, {
    required ScrollPositionValueGetter valueGetter,
    bool? animated,
    Direction? direction,
  }) {
    return ScrollPositionAdapter(
      Scrollable.of(context).position,
      valueGetter: valueGetter,
      animated: animated,
      direction: direction,
    );
  }

  final ScrollPosition scrollPosition;
  final ScrollPositionValueGetter valueGetter;

  @override
  void attach(AnimateController controller) {
    config(
      controller,
      _getValue() ?? 0,
      notifier: scrollPosition,
      listener: () {
        final double? value = _getValue();
        if (value != null) updateValue(value);
      },
    );
  }

  double? _getValue() {
    if (!scrollPosition.hasContentDimensions || !scrollPosition.hasPixels) {
      return null;
    }
    return valueGetter(scrollPosition);
  }
}

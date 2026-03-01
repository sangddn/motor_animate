import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';
import 'package:motor_animate/src/controllers/animate_controller.dart';

/// Adapters provide a mechanism to drive an animation from an arbitrary source.
/// For example, synchronizing an animation with a scroll, controlling
/// an animation with a slider input, or progressing an animation based on
/// the time of day.
///
/// [animated] specifies that the adapter should animate to new values. If `false`, it
/// will jump to the new value, if `true` it will animate to the value using a
/// duration calculated from the animation's total duration and the value change.
/// Defaults to `false`.
///
/// Setting [direction] to [Direction.forward] or [Direction.reverse] will cause
/// the adapter to only update if the new value is greater than or less than the
/// current value respectively.
///
/// Adapter implementations must expose an [attach] method which accepts the
/// [AnimateController] used by an [Animate] instance, and adds the logic
/// to drive it from an external source by updating its `value` (0-1). See the
/// included adapters for implementation examples.
abstract class Adapter {
  Adapter({bool? animated, this.direction}) : animated = animated ?? false;

  final bool animated;

  final Direction? direction;

  AnimateController? _controller;
  ChangeNotifier? _notifier;
  VoidCallback? _listener;
  double _value = 0;

  // this is called by Animate to associate the AnimateController.
  // implementers must call config.
  void attach(AnimateController controller) => config(controller, 0);

  // disassociates the controller, which also allows the adapter to be re-attached.
  @mustCallSuper
  void detach() {
    _notifier?.removeListener(_listener!);
    _notifier = _listener = _controller = null;
  }

  // called by implementers to attach the controller, and set an initial value.
  void config(
    AnimateController controller,
    double value, {
    ChangeNotifier? notifier,
    VoidCallback? listener,
  }) {
    assert(_controller == null, 'An adapter was assigned twice.');
    assert((notifier == null) == (listener == null));
    _controller = controller;
    _controller?.value = _value = value;
    _notifier = notifier?..addListener(listener!);
    _listener = listener;
  }

  // called by implementers to update the value. Manages direction and animated.
  void updateValue(double value) {
    AnimateController controller = _controller!;
    if (_value == value ||
        (direction == Direction.forward && value < _value) ||
        (direction == Direction.reverse && value > _value)) {
      return;
    }
    _value = value;

    if (!animated) {
      controller.value = value;
    } else {
      final double delta = (value - controller.value).abs();
      final Motion activeMotion = controller.motion;
      if (activeMotion is CurvedMotion) {
        final Duration base = activeMotion.duration;
        final int micros = (base.inMicroseconds * delta).round().clamp(
              1,
              base.inMicroseconds,
            );
        controller.animateTo(
          value,
          motion: Motion.curved(
            Duration(microseconds: micros),
            activeMotion.curve,
          ),
        );
      } else {
        controller.animateTo(value);
      }
    }
  }
}

enum Direction { forward, reverse }

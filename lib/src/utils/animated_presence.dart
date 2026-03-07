import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// Builds the animated wrapper used for a presence transition.
///
/// The provided [child] is the single logical child whose visibility is being
/// animated. Builders should add enter or exit effects to that child rather
/// than swap in a different widget tree.
typedef AnimatedPresenceBuilder = Widget Function(
    BuildContext context, Animate child);

/// Keeps the last non-null child mounted long enough for an exit animation to play.
///
/// This is useful when your UI wants to stay faithful to the underlying data:
/// pass a child while it exists, and pass `null` as soon as the data says it
/// is gone. [AnimatedPresence] retains the previously rendered child just long
/// enough to run [onDisappear].
///
/// ```dart
/// AnimatedPresence(
///   child: isSelected ? const Icon(Icons.check).animate() : null,
///   onAppear: (context, child) => child.fadeIn().scale(begin: const Offset(0.9, 0.9)),
///   onDisappear: (context, child) =>
///       child.fadeOut(motion: Motion.linear(180.ms)),
/// )
/// ```
///
/// This widget is intentionally about presence, not swapping:
///
/// - Use it when a single logical child toggles between present and absent.
/// - Do not use it as an `AnimatedSwitcher` replacement.
/// - If you are transitioning between different non-null children, use a
///   dedicated switching widget instead.
///
/// In practice, [child] should stay `null` or represent the same logical child
/// across builds. The [onAppear] and [onDisappear] builders should usually add
/// complementary effects to the provided [Animate] child.
class AnimatedPresence extends StatefulWidget {
  const AnimatedPresence({
    super.key,
    this.onAppear = defaultOnAppear,
    this.onDisappear = defaultOnDisappear,
    required this.child,
  });

  /// The default enter transition: fade the child in.
  static Widget defaultOnAppear(BuildContext context, Animate child) {
    return child.fadeIn();
  }

  /// The default exit transition: fade the child out.
  static Widget defaultOnDisappear(BuildContext context, Animate child) {
    return child.fadeOut();
  }

  /// Builds the widget shown while [child] is present.
  ///
  /// This should describe how the child enters, not how different children swap.
  final AnimatedPresenceBuilder onAppear;

  /// Builds the widget shown after [child] becomes `null`.
  ///
  /// The last non-null child is retained and passed here so an exit animation
  /// can finish before the widget is finally removed.
  final AnimatedPresenceBuilder onDisappear;

  /// The current child to show.
  ///
  /// Pass `null` as soon as the underlying data says the child is absent. When
  /// that happens, [AnimatedPresence] keeps the previous child alive long enough
  /// for [onDisappear] to complete.
  ///
  /// This should represent one logical child. If you need to animate between
  /// different non-null children, use a switching widget instead.
  final Animate? child;

  @override
  State<AnimatedPresence> createState() => _AnimatedPresenceState();
}

class _AnimatedPresenceState extends State<AnimatedPresence> {
  late Animate? _child = widget.child;

  void _onComplete(AnimationStatus status, Animate? target) {
    if (mounted && status == AnimationStatus.completed) {
      setState(() {
        _child = target;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final desiredChild = widget.child;
    if (desiredChild != null) {
      return widget.onAppear(
        context,
        desiredChild.listen(
          onStatus: (status) => _onComplete(status, desiredChild),
        ),
      );
    }
    if (_child != null) {
      return widget.onDisappear(
        context,
        _child!.listen(onStatus: (status) => _onComplete(status, null)),
      );
    }
    return const SizedBox.shrink();
  }
}

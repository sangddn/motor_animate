import 'package:flutter/widgets.dart';
import 'package:motor_animate/src/warn.dart';

import 'defaults.dart';
import '../motor_animate.dart';

/// {@template motor_animate.animate_shared_configuration}
/// Shared configuration for [Animate] and [AnimateWidgetExtensions.animate]:
///
/// - [effects]: optional effect list to seed before chained calls.
/// - [onInit]: called once after an internal controller is initialized.
/// - [onPlay]: called whenever autoplay (or replay) starts.
/// - [onComplete]: called when the timeline completes.
/// - [autoPlay]: if `false`, suppresses automatic playback.
/// - [delay]: one-time startup delay before playback.
/// - [controller]: external [AnimateController] to drive this instance.
/// - [adapter]: external source adapter; takes over controller progress.
/// - [target]: declarative target value (`0..1`) to animate toward.
/// - [initialTarget]: one-time starting value for the first target-driven play.
/// - [replayOnChange]: changing value triggers a replay pass.
/// - [value]: immediate controller position (`0..1`).
/// {@endtemplate}
///
/// The Flutter Animate library makes adding beautiful animated effects to your widgets
/// simple. It supports both a declarative and chained API. The latter is exposed
/// via the `Widget.animate` extension, which simply wraps the widget in `Animate`.
///
/// ```
/// // declarative:
/// Animate(child: foo, effects: [FadeEffect(), ScaleEffect()])
///
/// // chained API:
/// foo.animate().fade().scale() // equivalent to above
/// ```
///
/// Effects are always run in parallel (ie. the fade and scale effects in the
/// example above would be run simultaneously), but you can apply delays to
/// offset them or run them in sequence.
///
/// All effects classes are immutable, and can be shared between `Animate`
/// instances, which lets you create libraries of effects to reuse throughout
/// your app.
///
/// ```
/// List<Effect> transitionIn = [
///   FadeEffect(motion: Motion.curved(100.ms, Curves.easeOut)),
///   ScaleEffect(begin: 0.8, motion: Motion.curved(100.ms, Curves.easeIn))
/// ];
/// // then:
/// Animate(child: foo, effects: transitionIn)
/// // or:
/// foo.animate(effects: transitionIn)
/// ```
///
/// Effects inherit some of their properties (delay and motion) from the
/// previous effect if unspecified. All effects have
/// reasonable defaults, so they can be used simply: `foo.animate().fade()`
///
/// Note that all effects are composed together, not run sequentially. For example,
/// the following would not fade in myWidget, because the fadeOut effect would still be
/// applying an opacity of 0:
///
/// ```
/// myWidget.animate().fadeOut(motion: Motion.linear(200.ms)).fadeIn(delay: 200.ms)
/// ```
///
/// See [SwapEffect] for one approach to work around this.

// ignore: must_be_immutable
class Animate extends StatefulWidget with AnimateManager<Animate> {
  /// Default motion for effects when no explicit timing is provided.
  static Motion get defaultMotion => animateDefaultMotion;

  static set defaultMotion(Motion value) {
    animateDefaultMotion = value;
  }

  /// Default curve for curve-based effects when no explicit curve is provided.
  static Curve defaultCurve = Cubic(0.4, 0.0, 0.2, 1.0);

  /// Default duration for curve-based effects when no explicit duration is provided.
  static Duration defaultDuration = Duration(milliseconds: 300);

  /// If true, then animations will automatically restart whenever a hot reload
  /// occurs. This is useful for testing animations quickly during development.
  ///
  /// You can get similar results for an individual animation by passing it a
  /// [UniqueKey], which will cause it to restart each time it is rebuilt.
  ///
  /// ```
  /// myWidget.animate(key: UniqueKey()).fade()
  /// ```
  static bool restartOnHotReload = false;

  /// Widget types to reparent, mapped to a method that handles that type. This is used
  /// to make it easy to work with widgets that require specific parents. For example,
  /// the [Positioned] widget, which needs its immediate parent to be a [Stack].
  ///
  /// Handles [Flexible], [Positioned], and [Expanded] by default, but you can add additional
  /// handlers as appropriate. Example, this would add support for a hypothetical
  /// "AlignPositioned" widget, that has an `alignment` property.
  ///
  /// ```
  /// Animate.reparentTypes[AlignPositioned] = (parent, child) {
  ///   AlignPositioned o = parent as AlignPositioned;
  ///   return AlignPositioned(alignment: o.alignment, child: child);
  /// }
  /// ```
  static Map reparentTypes = <Type, ReparentChildBuilder>{
    Flexible: (parent, child) {
      Flexible o = parent as Flexible;
      return Flexible(key: o.key, flex: o.flex, fit: o.fit, child: child);
    },
    Positioned: (parent, child) {
      Positioned o = parent as Positioned;
      return Positioned(
        key: o.key,
        left: o.left,
        top: o.top,
        right: o.right,
        bottom: o.bottom,
        width: o.width,
        height: o.height,
        child: child,
      );
    },
    Expanded: (parent, child) {
      Expanded o = parent as Expanded;
      return Expanded(key: o.key, flex: o.flex, child: child);
    },
  };

  /// Creates an [Animate] instance that manages effects for [child].
  ///
  /// The [child] defaults to a zero-sized box when omitted.
  ///
  /// {@macro motor_animate.animate_shared_configuration}
  Animate({
    super.key,
    this.child = const SizedBox.shrink(),
    List<Effect>? effects,
    this.onInit,
    this.onPlay,
    this.onComplete,
    bool? autoPlay,
    Duration? delay,
    this.controller,
    this.adapter,
    this.value,
    this.target,
    this.initialTarget,
    this.replayOnChange,
  })  : autoPlay = autoPlay ?? true,
        delay = delay ?? Duration.zero {
    warn(
      autoPlay != false || onPlay == null || replayOnChange != null,
      'Animate.onPlay is not called when Animate.autoPlay=false unless Animate.replayOnChange triggers playback',
    );
    warn(
      controller == null || onInit == null,
      'Animate.onInit is not called when used with Animate.controller',
    );
    if (this.delay != Duration.zero) {
      String s = "Animate.delay has no effect when used with";
      warn(autoPlay != false, '$s Animate.autoPlay=false');
      warn(adapter == null, '$s Animate.adapter');
      warn(target == null, '$s Animate.target');
      warn(value == null, '$s Animate.value');
    }
    warn(
      initialTarget == null || target != null,
      'Animate.initialTarget has no effect without Animate.target',
    );
    _entries = [];
    if (effects != null) addEffects(effects);
  }

  /// The widget to apply animated effects to.
  final Widget child;

  /// Called immediately after the controller is fully initialized, before
  /// the [Animate.delay] or the animation starts playing (see: [onPlay]).
  /// This is not called if an external [controller] is provided.
  ///
  /// For example, this would pause the animation at its halfway point, and
  /// save a reference to the controller so it can be started later.
  /// ```
  /// foo.animate(
  ///   autoPlay: false,
  ///   onInit: (controller) {
  ///     controller.value = 0.5;
  ///     _myController = controller;
  ///   }
  /// ).slideY()
  /// ```
  final AnimateCallback? onInit;

  /// Called when the animation begins playing (ie. after [Animate.delay],
  /// immediately after [AnimateController.forward] is called).
  /// Provides an opportunity to manipulate the [AnimateController]
  /// (ex. to loop, reverse, stop, etc). This is not called if [autoPlay]
  /// is `false`, unless [replayOnChange] triggers a replay. See also: [onInit].
  ///
  /// For example, this would pause the animation at its start:
  /// ```
  /// foo.animate(
  ///   onPlay: (controller) => controller.stop()
  /// ).fadeIn()
  /// ```
  /// This would loop the animation, reversing it on each loop:
  /// ```
  /// foo.animate(
  ///   onPlay: (controller) => controller.repeat(reverse: true)
  /// ).fadeIn()
  /// ```
  final AnimateCallback? onPlay;

  /// Called when all effects complete. Provides an opportunity to
  /// manipulate the [AnimateController] (ex. to loop, reverse, etc).
  final AnimateCallback? onComplete;

  /// Setting [autoPlay] to `false` prevents the animation from automatically
  /// starting its controller (ie. calling [AnimateController.forward]).
  final bool autoPlay;

  /// Defines a delay before the animation is started. Unlike [Effect.delay],
  /// this is not a part of the overall animation, and only runs once if the
  /// animation is looped. [onPlay] is called after this delay.
  final Duration delay;

  /// An external [AnimateController] can optionally be specified. By default
  /// Animate creates its own controller internally, which can be accessed via
  /// [onInit] or [onPlay].
  ///
  /// While a controller can be shared between multiple Animate instances,
  /// unexpected behaviors and errors will occur if the animations do not have
  /// identical total durations.
  final AnimateController? controller;

  /// An [Adapter] can drive the animation from an external source (ex. a [ScrollController],
  /// [ValueNotifier], or arbitrary `0-1` value). For more information see [Adapter]
  /// or an adapter class ([ChangeNotifierAdapter], [ScrollAdapter], [ValueAdapter],
  /// [ValueNotifierAdapter]).
  ///
  /// If an adapter is provided, then [delay] is ignored, and you should not
  /// make changes to the [AnimateController] directly (ex. via [onPlay])
  /// because it can cause unexpected results.
  final Adapter? adapter;

  /// Sets a target position for the animation between 0 (start) and 1 (end).
  /// When [target] is changed, it will animate to the new position.
  ///
  /// Ex. fade and scale a button when an `_over` state changes:
  /// ```
  /// MyButton().animate(target: _over ? 1 : 0)
  ///   .fade(end: 0.8).scaleXY(end: 1.1)
  /// ```
  final double? target;

  /// Sets the starting value used for the first target-driven playback.
  /// This allows an initial transition even when [target] starts at its final value.
  ///
  /// For example, this animates from `0` to `1` on first build, then continues
  /// using [target] updates normally:
  ///
  /// ```
  /// MyPanel().animate(target: 1, initialTarget: 0).fade()
  /// ```
  final double? initialTarget;

  /// Replays the animation whenever this value changes between widget rebuilds.
  /// This is useful for one-shot state transitions without having to allocate a
  /// new key.
  ///
  /// Ex. replay a collapse/expand transition when `_isCollapsed` changes:
  /// ```
  /// MyPanel().animate(replayOnChange: _isCollapsed).fade().scale()
  /// ```
  final Object? replayOnChange;

  /// Sets an initial position for the animation between 0 (start) and 1 (end).
  /// This corresponds to the `value` of the animation's [controller].
  /// When [value] is changed, it will jump to the new position.
  ///
  /// For example, this can be used with [autoPlay]`=false` to display an animation
  /// at a specific point (half way through a fade in this case):
  ///
  /// ```
  /// foo.animate(value: 0.5, autoPlay: false).fadeIn()
  /// ```
  final double? value;

  late final List<EffectEntry> _entries;
  Duration _duration = Duration.zero;
  EffectEntry? _lastEntry;
  Duration _baseDelay = Duration.zero;

  /// The total duration for all effects.
  Duration get duration => _duration;

  @override
  State<Animate> createState() => _AnimateState();

  /// Adds an effect. This is mostly used by [Effect] extension methods to append effects
  /// to an [Animate] instance.
  @override
  Animate addEffect(Effect effect) {
    EffectEntry? prior = _lastEntry;

    Duration zero = Duration.zero, delay = zero;
    if (effect is ThenEffect) {
      delay = _baseDelay = (prior?.end ?? zero) + (effect.delay ?? zero);
    } else if (effect.delay != null) {
      delay = _baseDelay + effect.delay!;
    } else {
      delay = prior?.delay ?? _baseDelay;
    }

    assert(delay >= zero, 'Calculated delay cannot be negative.');

    final Motion resolvedMotion =
        effect.motion ?? prior?.motion ?? Animate.defaultMotion;

    EffectEntry entry = EffectEntry(
      effect: effect,
      delay: delay,
      motion: resolvedMotion,
      owner: this,
    );

    _entries.add(entry);
    _lastEntry = entry;
    if (entry.end > _duration && effect is! ThenEffect) _duration = entry.end;
    return this;
  }
}

class _AnimateState extends State<Animate> with SingleTickerProviderStateMixin {
  late AnimateController _controller;
  bool _isInternalController = false;
  bool _isFirstPlay = true;
  Adapter? _adapter;
  Future<void>? _delayed;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(Animate oldWidget) {
    if (oldWidget.controller != widget.controller ||
        oldWidget._duration != widget._duration) {
      _initController();
      _play();
    } else if (oldWidget.adapter != widget.adapter) {
      _initAdapter();
    } else if (widget.target != oldWidget.target ||
        widget.value != oldWidget.value ||
        widget.replayOnChange != oldWidget.replayOnChange) {
      _play(forceReplay: widget.replayOnChange != oldWidget.replayOnChange);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Animate.restartOnHotReload) _restart();
  }

  void _restart() {
    _delayed?.ignore();
    _isFirstPlay = true;
    _initController();
    _updateValue();
    _delayed = Future.delayed(widget.delay, () => _play());
  }

  void _initController() {
    AnimateController? controller;
    bool callback = false;

    if (widget.controller != null) {
      // externally provided AnimateController.
      _disposeController();
      controller = widget.controller!;
    } else if (!_isInternalController) {
      // create a new internal AnimateController.
      controller = AnimateController(vsync: this);
      callback = _isInternalController = true;
    } else {
      // pre-existing controller.
    }

    if (controller != null) {
      // new controller.
      _controller = controller;
      _controller.addStatusListener(_handleAnimationStatus);
    }

    _controller.motion = _timelineMotion(widget._duration);

    _initAdapter();

    if (callback) widget.onInit?.call(_controller);
  }

  void _initAdapter() {
    _adapter?.detach();
    _adapter = widget.adapter;
    _adapter?.attach(_controller);
  }

  void _disposeController() {
    if (_isInternalController) _controller.dispose();
    _isInternalController = false;
  }

  @override
  void dispose() {
    _adapter?.detach();
    _delayed?.ignore();
    _disposeController();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete?.call(_controller);
    }
  }

  void _play({bool forceReplay = false}) {
    _delayed?.ignore(); // for poorly timed hot reloads.
    _updateValue();
    double? pos = widget.target;
    if (pos != null) {
      if (_isFirstPlay && widget.initialTarget != null) {
        _controller.value = widget.initialTarget!;
      }
      _isFirstPlay = false;
      _controller.animateTo(pos);
    } else if ((widget.autoPlay || forceReplay) && _adapter == null) {
      _isFirstPlay = false;
      _controller.forward(from: widget.value ?? 0);
      widget.onPlay?.call(_controller);
    }
  }

  void _updateValue() {
    if (widget.value == null) return;
    _controller.value = widget.value!;
  }

  Motion _timelineMotion(Duration span) {
    if (span <= Duration.zero) {
      return const Motion.linear(Duration(microseconds: 1));
    }
    return Motion.linear(span);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child, parent = child;
    ReparentChildBuilder? reparent = Animate.reparentTypes[child.runtimeType];
    if (reparent != null) child = (child as dynamic).child;
    for (EffectEntry entry in widget._entries) {
      child = entry.effect.build(context, child, _controller, entry);
    }
    return reparent?.call(parent, child) ?? child;
  }
}

/// Adds [Animate] related extensions to [Widget].
extension AnimateWidgetExtensions on Widget {
  /// Wraps the target [Widget] in an [Animate] instance, and returns
  /// the instance for chaining calls.
  /// Ex. `myWidget.animate()` is equivalent to `Animate(child: myWidget)`.
  ///
  /// {@macro motor_animate.animate_shared_configuration}
  Animate animate({
    Key? key,
    List<Effect>? effects,
    AnimateCallback? onInit,
    AnimateCallback? onPlay,
    AnimateCallback? onComplete,
    bool? autoPlay,
    Duration? delay,
    AnimateController? controller,
    Adapter? adapter,
    double? target,
    double? initialTarget,
    Object? replayOnChange,
    double? value,
  }) =>
      Animate(
        key: key,
        effects: effects,
        onInit: onInit,
        onPlay: onPlay,
        onComplete: onComplete,
        autoPlay: autoPlay,
        delay: delay,
        controller: controller,
        adapter: adapter,
        target: target,
        initialTarget: initialTarget,
        replayOnChange: replayOnChange,
        value: value,
        child: this,
      );
}

/// The builder type used by [Animate.reparentTypes]. It must accept an existing
/// parent widget, and rebuild it with the provided child. In effect, it clones
/// the provided parent widget with the new child.
typedef ReparentChildBuilder = Widget Function(Widget parent, Widget child);

/// Function signature for [Animate] callbacks.
typedef AnimateCallback = void Function(AnimateController controller);

# motor_animate docs

## Design goals

- Preserve `flutter_animate` ergonomics.
- Make timing motion-native (`motor`) end-to-end.
- Keep imperative control first-class.

## Public timing model

For effects:

- `delay` offsets start time.
- `motion` defines progression.
- No public `duration` or `curve` fields.
- Package default is `Animate.defaultMotion = const Motion.smoothSpring(snapToEnd: true)`.

For curves, use:

```dart
motion: Motion.curved(400.ms, Curves.easeOut)
```

## Imperative semantics

`AnimateController` is motion-first:

- Default controller motion is set in constructor (defaults to `Animate.defaultMotion`).
- `animateTo` and `animateBack` can override motion per call.
- `repeat` and `loop` are implemented via motion phase sequences.

Lifecycle hooks:

- `onLoop(loopCount)`
- `onSegmentStart(segmentIndex, from, to, motion)`
- `onSegmentComplete(segmentIndex, from, to, motion)`

`playSequence` exposes typed phase playback directly for advanced graphs.

## Animated presence

`AnimatedPresence` is a small utility for mount/unmount transitions.

- Pass a non-null child while the underlying data says the child exists.
- Pass `null` immediately when the data says it is gone.
- The last non-null child is retained just long enough to run `onDisappear`.

Use it for presence, not switching. It is not meant to coordinate transitions
between different non-null children; for that, use a dedicated switching
pattern such as `AnimatedSwitcher`.

## Collection presence

`MultiAnimatedPresence` applies the same idea to keyed collections.

- Provide `items` plus a stable `keyOf` callback.
- Build each row with `itemBuilder`.
- Choose the underlying host with the delegate exposed to `builder`.

Typical hosts:

- `ListView.builder` via `delegate.itemCount`, `delegate.itemBuilder`, and
  `delegate.findChildIndexCallback`
- eager/custom children via `delegate.buildChildren(context)`
- sliver-style hosts via `delegate.buildSliverChildDelegate()`

Behavior notes:

- same key => same logical item, no leave/enter cycle
- removed key => retained entry plays `onDisappear`, then is removed
- same key returning before exit completes => exiting entry is revived
- transition builders should animate the provided child instead of replacing it

Like `AnimatedPresence`, this is for insert/remove presence, not animated
switching or full reorder choreography.

## Internals (high level)

- Each effect resolves to an `EffectEntry(delay, motion, span)`.
- Span is estimated from motion settle behavior.
- Total animation duration is derived from entry end times.

## Source map

- Core widget: `lib/src/animate.dart`
- Controller: `lib/src/controllers/animate_controller.dart`
- Loop extension: `lib/src/extensions/animation_controller_loop_extensions.dart`
- Effect timing entry: `lib/src/motor_animate.dart`
- Effects: `lib/src/effects/*`

## Example

Run the example app and open the `Imperative` tab for controller-focused demos.

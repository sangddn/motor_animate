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

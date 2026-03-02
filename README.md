# motor_animate

Motion-native animation effects for Flutter.

`motor_animate` is a fork of `flutter_animate` that keeps the familiar chaining and imperative ergonomics, but runs on [`motor`](https://pub.dev/packages/motor) motions.

## Install

```yaml
dependencies:
  motor_animate:
    git:
      url: https://github.com/sangddn/motor_animate.git
      ref: main
```

## Quick start

```dart
import 'package:motor/motor.dart';
import 'package:motor_animate/motor_animate.dart';

Text('Hello')
    .animate()
    .fadeIn(motion: Motion.linear(300.ms))
    .scale(delay: 120.ms, motion: Motion.smoothSpring());

// replay on state changes
Text('Filters')
    .animate(replayOnChange: isCollapsed)
    .fadeIn(motion: Motion.linear(220.ms))
    .slideY(begin: 0.1);

// first build animates 0 -> target, then target drives normally
Text('Badge')
    .animate(target: 1, initialTarget: 0)
    .fadeIn(motion: Motion.linear(280.ms));
```

Package default:

```dart
Animate.defaultMotion == const Motion.smoothSpring(snapToEnd: true);
```

Override globally if needed:

```dart
Animate.defaultMotion = Motion.curved(450.ms, Curves.easeOutCubic);
```

## Imperative API (motion-first)

```dart
late final AnimateController controller;

@override
void initState() {
  super.initState();
  controller = AnimateController(
    vsync: this,
    motion: Motion.smoothSpring(extraBounce: 0.12),
  );
}

// One-shot motion override
controller.animateTo(1, motion: Motion.curved(300.ms, Curves.easeOut));

// Repeating with lifecycle hooks
controller.loop(
  reverse: true,
  motion: Motion.linear(350.ms),
  onLoop: (loop) => debugPrint('loop $loop'),
  onSegmentStart: (i, from, to, _) => debugPrint('start $i: $from->$to'),
  onSegmentComplete: (i, from, to, _) => debugPrint('done $i: $from->$to'),
);
```

## Phase sequences

Use `playSequence` for phase-based motion graphs:

```dart
final sequence = MotionSequence.states(
  {
    'idle': 0.0,
    'focus': 0.6,
    'burst': 1.0,
  },
  motion: Motion.smoothSpring(),
  loop: LoopMode.pingPong,
);

controller.playSequence(
  sequence,
  onLoop: (loop) => debugPrint('phase loop $loop'),
  onSegmentStart: (i, from, to, _) => debugPrint('$from -> $to'),
);
```

## Migration from flutter_animate

- `duration: d, curve: c` -> `motion: Motion.curved(d, c)`
- Default timing -> `Animate.defaultMotion`
- Per-call timing override on controller methods -> `motion:`
- Repeats/loops are motion-phase driven (sequence semantics)

## Example app

```bash
cd example
flutter run
```

The example includes an `Imperative` screen focused on controller loops, phase sequences, and lifecycle hooks.

More details: [docs/README.md](docs/README.md), [example/README.md](example/README.md).

# motor_animate example

Shows practical `motor_animate` usage across effect chaining, adapters, and imperative control.

## Run

```bash
flutter pub get
flutter run
```

## Screens

- `Everything`: broad effect catalog using motion timing.
- `Visual`: shader and heavy visual effects.
- `Adapter`: scroll/notifier-driven animation.
- `Imperative`: `AnimateController` loops, phase sequences, and lifecycle hooks.

## What to look for

- Effects use `motion:` (not `duration:`/`curve:`).
- Package default motion is `const Motion.smoothSpring()`.
- Curves are modeled via `Motion.curved(...)`.
- Loop/repeat behavior is phase-sequence based.

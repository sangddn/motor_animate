# Changelog

## [0.1.0] - 2026-03-01

### Added

- full fork of `flutter_animate` API surface in `motor_animate`
- new motor-backed imperative `AnimateController`
- `Animate`, effects, adapters, and extension pipeline migrated to motor controller plumbing
- full test suite migrated and passing
- example app forked and extended with an imperative motor-motion showcase tab
- `Animate.replayOnChange` / `.animate(replayOnChange: value)` to replay when a tracked value changes
- `Animate.initialTarget` / `.animate(target: x, initialTarget: y)` for one-time first target playback from `y` to `x`

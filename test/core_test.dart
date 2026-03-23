import 'package:flutter/material.dart';
import 'package:motor_animate/src/warn.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_animate/motor_animate.dart';

import 'tester_extensions.dart';

double _secondsFor(Duration duration) =>
    duration.inMicroseconds / Duration.microsecondsPerSecond;

void main() {
  // can really only test if warn throws an error:
  test('warn', () async {
    warn(false, 'testing warn()');
  });

  testWidgets('curved tween w/ 1000s duration', (tester) async {
    const curve = Curves.easeOut;
    final animation = const FlutterLogo().animate().fade(
          begin: .25,
          end: .75,
          motion: Motion.curved(1000.ms, curve),
        );
    // wait 500ms and check middle pos
    await tester.pumpAnimation(animation, initialDelay: 500.ms);
    double expectedValue = .25 + curve.transform(.5) * .5;
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      expectedValue,
      'opacity',
    );
    // wait another 500ms and check end pos
    await tester.pump(500.ms);
    expectedValue = .25 + curve.transform(1) * .5;
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      expectedValue,
      'opacity',
    );
  });

  testWidgets('linear tween w/ 500ms duration', (tester) async {
    final animation = const FlutterLogo().animate().fade(
          begin: .25,
          end: .75,
          motion: Motion.linear(500.ms),
        );
    await tester.pumpAnimation(animation, initialDelay: 250.ms);
    // check halfway
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      .5,
      'opacity',
    );
    // check end
    await tester.pump(250.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      .75,
      'opacity',
    );
  });

  test('bouncy cupertino springs use settle span instead of nominal duration',
      () {
    const motion = CupertinoMotion.bouncy(
      duration: Duration(milliseconds: 500),
      extraBounce: 0.1,
      snapToEnd: true,
    );

    final simulation = motion.createSimulation(start: 0, end: 1, velocity: 0);
    final span = EffectEntry.estimateSpanFor(motion);

    expect(
      span,
      greaterThan(motion.duration),
      reason:
          'Bouncy Cupertino springs need extra tail time beyond their nominal duration to avoid visual cutoff.',
    );
    expect(
      (1 - simulation.x(_secondsFor(span))).abs(),
      lessThanOrEqualTo(simulation.tolerance.distance),
    );
  });

  testWidgets('delayed tween', (tester) async {
    final animation = const FlutterLogo().animate().fade(
          delay: 1.seconds,
          motion: Motion.linear(1.seconds),
        );

    // Wait and expect it hasn't started yet
    await tester.pumpAnimation(animation, initialDelay: 500.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      0,
      'opacity',
    );

    // Wait and expect it is now half-way through
    await tester.pump(1000.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      .5,
      'opacity',
    );
  });

  testWidgets('delayed animate', (tester) async {
    // use a 1 second delay and 1 second duration
    final animation = const FlutterLogo()
        .animate(delay: 1.seconds)
        .fade(motion: Motion.linear(1.seconds));

    // Wait 500ms expect it hasn't started yet
    await tester.pumpAnimation(animation, initialDelay: 500.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      0,
      'opacity',
    );

    // Wait 1s expect it is now half-way through (two pumps are required to get the delay to fire)
    await tester.pump(500.ms);
    await tester.pump(500.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      .5,
      'opacity',
    );
  });

  testWidgets('replayOnChange replays when the value changes', (tester) async {
    Widget buildAnim(bool isCollapsed) {
      return const FlutterLogo()
          .animate(
            replayOnChange: isCollapsed,
          )
          .fade(motion: Motion.linear(1.seconds));
    }

    await tester.pumpAnimation(buildAnim(false), initialDelay: 1.seconds);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      1,
      'opacity',
    );

    await tester.pumpAnimation(buildAnim(true), initialDelay: 500.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      .5,
      'opacity',
    );
  });

  testWidgets('replayOnChange does not replay when the value is unchanged',
      (tester) async {
    Widget buildAnim(bool isCollapsed) {
      return const FlutterLogo()
          .animate(
            replayOnChange: isCollapsed,
          )
          .fade(motion: Motion.linear(1.seconds));
    }

    await tester.pumpAnimation(buildAnim(false), initialDelay: 1.seconds);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      1,
      'opacity',
    );

    await tester.pumpAnimation(buildAnim(false), initialDelay: 500.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      1,
      'opacity',
    );
  });

  testWidgets('replayOnChange can replay even when autoPlay is false',
      (tester) async {
    Widget buildAnim(bool isCollapsed) {
      return const FlutterLogo()
          .animate(
            autoPlay: false,
            replayOnChange: isCollapsed,
          )
          .fade(motion: Motion.linear(1.seconds));
    }

    await tester.pumpAnimation(buildAnim(false), initialDelay: 500.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      0,
      'opacity',
    );

    await tester.pumpAnimation(buildAnim(true), initialDelay: 500.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      .5,
      'opacity',
    );
  });

  testWidgets('initialTarget animates to initial target on first build',
      (tester) async {
    Widget buildAnim(double target) {
      return const FlutterLogo()
          .animate(
            target: target,
            initialTarget: 0,
          )
          .fade(motion: Motion.linear(1.seconds));
    }

    await tester.pumpAnimation(buildAnim(1), initialDelay: 500.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      .5,
      'opacity',
    );

    await tester.pump(500.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      1,
      'opacity',
    );
  });

  testWidgets('initialTarget only applies to first target playback',
      (tester) async {
    Widget buildAnim(double target) {
      return const FlutterLogo()
          .animate(
            target: target,
            initialTarget: 0,
          )
          .fade(motion: Motion.linear(1.seconds));
    }

    await tester.pumpAnimation(buildAnim(1), initialDelay: 1.seconds);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      1,
      'opacity',
    );

    await tester.pumpAnimation(buildAnim(0.5), initialDelay: 250.ms);
    tester.expectWidgetWithDouble<FadeTransition>(
      (w) => w.opacity.value,
      .875,
      'opacity',
    );
  });
}

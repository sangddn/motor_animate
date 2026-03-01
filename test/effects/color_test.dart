import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_animate/motor_animate.dart';

import '../tester_extensions.dart';

void main() {
  testWidgets('ColorEffect: core', (tester) async {
    BlendMode blend = BlendMode.colorDodge;
    Color begin = Colors.blue, end = Colors.red;

    final animation = const FlutterLogo().animate().color(
          motion: Motion.linear(1000.ms),
          blendMode: blend,
          begin: begin,
          end: end,
        );

    // Check begin:
    await tester.pumpAnimation(animation);
    tester.expectWidgetWithBool<ColorFiltered>(
      (o) => o.colorFilter == ColorFilter.mode(begin, blend),
      true,
      'colorFilter @ 0%',
    );

    // Midpoint should no longer match the legacy sRGB ColorTween interpolation.
    await tester.pump(500.ms);
    final midpointWidget =
        tester.widget<ColorFiltered>(find.byType(ColorFiltered).last);
    final legacyMidpoint = ColorTween(begin: begin, end: end).evaluate(
      const AlwaysStoppedAnimation<double>(0.5),
    );
    expect(
      midpointWidget.colorFilter,
      isNot(ColorFilter.mode(legacyMidpoint!, blend)),
    );

    // Check end:
    await tester.pump(500.ms);
    tester.expectWidgetWithBool<ColorFiltered>(
      (o) => o.colorFilter == ColorFilter.mode(end, blend),
      true,
      'colorFilter @ 100%',
    );
  });
}

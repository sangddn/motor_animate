import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_animate/motor_animate.dart';

import '../tester_extensions.dart';

void main() {
  testWidgets('SlideEffect: slide', (tester) async {
    final animation = const FlutterLogo().animate().slide(
          motion: Motion.linear(1000.ms),
          begin: Offset.zero,
          end: const Offset(_slideAmt, _slideAmt),
        );

    // check halfway
    await tester.pumpAnimation(animation, initialDelay: 500.ms);
    _verifySlide(tester, _slideAmt / 2, _slideAmt / 2);
  });

  testWidgets('SlideEffect: slideX', (tester) async {
    final animation = const FlutterLogo().animate().slideX(
          motion: Motion.linear(1000.ms),
          end: _slideAmt,
        );

    // check halfway
    await tester.pumpAnimation(animation, initialDelay: 500.ms);
    _verifySlide(tester, _slideAmt / 2, 0);
  });

  testWidgets('SlideEffect: slideY', (tester) async {
    final animation = const FlutterLogo().animate().slideY(
          motion: Motion.linear(1000.ms),
          end: _slideAmt,
        );

    // check halfway
    await tester.pumpAnimation(animation, initialDelay: 500.ms);
    _verifySlide(tester, 0, _slideAmt / 2);
  });
}

Future<void> _verifySlide(WidgetTester tester, double x, double y) async {
  tester.expectWidgetWithDouble<SlideTransition>(
    (o) => o.position.value.dx,
    x,
    'dx',
  );
  tester.expectWidgetWithDouble<SlideTransition>(
    (o) => o.position.value.dy,
    y,
    'dy',
  );
}

const double _slideAmt = 1;

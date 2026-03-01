import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_animate/motor_animate.dart';

import '../tester_extensions.dart';

void main() {
  testWidgets('TintEffect: tint', (tester) async {
    final animation = const FlutterLogo().animate().tint(
          motion: Motion.linear(1000.ms),
          color: _color,
        );

    // Check halfway
    await tester.pumpAnimation(animation, initialDelay: 500.ms);
    _verifyTint(tester, 0.5);
  });

  testWidgets('TintEffect: untint', (tester) async {
    final animation = const FlutterLogo().animate().untint(
          motion: Motion.linear(1000.ms),
          color: _color,
        );

    // Check halfway
    await tester.pumpAnimation(animation, initialDelay: 500.ms);
    _verifyTint(tester, 0.5);
  });
}

Future<void> _verifyTint(WidgetTester tester, double amount) async {
  // create a colorFilter to compare to the one in the widget tree
  var expectedFilter = ColorFilter.matrix(
    TintEffect.getTintMatrix(amount, _color),
  );
  tester.expectWidgetWithBool<ColorFiltered>(
    (o) => o.colorFilter == expectedFilter,
    true,
    'colorFilter',
  );
}

const Color _color = Colors.blue;

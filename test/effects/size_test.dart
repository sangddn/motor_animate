import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_animate/motor_animate.dart';

import '../tester_extensions.dart';

void main() {
  testWidgets('SizeEffect: size', (tester) async {
    final animation = const SizedBox(width: 100, height: 40).animate().size(
          motion: Motion.linear(1000.ms),
          end: const Offset(0.5, 2),
          alignment: Alignment.bottomRight,
        );

    await tester.pumpAnimation(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: animation),
      ),
      initialDelay: 500.ms,
    );

    tester.expectWidgetWithDouble<Align>(
        (o) => o.widthFactor!, 0.75, 'widthFactor');
    tester.expectWidgetWithDouble<Align>(
        (o) => o.heightFactor!, 1.5, 'heightFactor');
    expect(
      tester.widget<Align>(find.byType(Align)).alignment,
      Alignment.bottomRight,
    );
    expect(tester.getSize(find.byType(Align)), const Size(75, 60));
  });

  testWidgets('SizeEffect: sizeXY', (tester) async {
    final animation = const SizedBox(width: 100, height: 40).animate().sizeXY(
          motion: Motion.linear(1000.ms),
          end: 2,
        );

    await tester.pumpAnimation(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: animation),
      ),
      initialDelay: 500.ms,
    );

    tester.expectWidgetWithDouble<Align>(
        (o) => o.widthFactor!, 1.5, 'widthFactor');
    tester.expectWidgetWithDouble<Align>(
        (o) => o.heightFactor!, 1.5, 'heightFactor');
    expect(
      tester.widget<Align>(find.byType(Align)).alignment,
      Alignment.center,
    );
    expect(tester.getSize(find.byType(Align)), const Size(150, 60));
  });

  testWidgets('SizeEffect: sizeX', (tester) async {
    final animation = const SizedBox(width: 100, height: 40).animate().sizeX(
          motion: Motion.linear(1000.ms),
          end: 2,
        );

    await tester.pumpAnimation(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: animation),
      ),
      initialDelay: 500.ms,
    );

    tester.expectWidgetWithDouble<Align>(
        (o) => o.widthFactor!, 1.5, 'widthFactor');
    tester.expectWidgetWithDouble<Align>(
        (o) => o.heightFactor!, 1.0, 'heightFactor');
    expect(
      tester.widget<Align>(find.byType(Align)).alignment,
      Alignment.center,
    );
    expect(tester.getSize(find.byType(Align)), const Size(150, 40));
    expect(find.byType(ClipRect), findsNothing);
  });

  testWidgets('SizeEffect: sizeY', (tester) async {
    final animation = const SizedBox(width: 100, height: 40).animate().sizeY(
          motion: Motion.linear(1000.ms),
          end: 2,
          alignment: Alignment.topCenter,
          clip: Clip.hardEdge,
        );

    await tester.pumpAnimation(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: animation),
      ),
      initialDelay: 500.ms,
    );

    tester.expectWidgetWithDouble<Align>(
        (o) => o.widthFactor!, 1.0, 'widthFactor');
    tester.expectWidgetWithDouble<Align>(
        (o) => o.heightFactor!, 1.5, 'heightFactor');
    expect(
      tester.widget<Align>(find.byType(Align)).alignment,
      Alignment.topCenter,
    );
    expect(tester.widget<ClipRect>(find.byType(ClipRect)).clipBehavior,
        Clip.hardEdge);
    expect(tester.getSize(find.byType(Align)), const Size(100, 60));
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_animate/motor_animate.dart';

void main() {
  testWidgets('animateTo supports one-shot motion override', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final controller = AnimateController(
      vsync: tester,
      motion: Motion.linear(1000.ms),
    );
    addTearDown(controller.dispose);

    controller.animateTo(1, motion: Motion.linear(200.ms));
    await tester.pump();
    await tester.pump(100.ms);
    expect(controller.value, closeTo(0.5, 0.05));
    await tester.pump(100.ms);
    expect(controller.value, closeTo(1.0, 0.01));

    controller.reset();
    controller.animateTo(1);
    await tester.pump();
    await tester.pump(200.ms);
    expect(controller.value, closeTo(0.2, 0.05));
    controller.stop(canceled: true);
  });

  testWidgets('playSequence emits segment and transition lifecycle hooks',
      (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final controller = AnimateController(
      vsync: tester,
      motion: Motion.linear(100.ms),
    );
    addTearDown(controller.dispose);

    final events = <String>[];
    final transitions = <String>[];
    final loops = <int>[];

    final sequence = MotionSequence<String, double>.states(
      const <String, double>{
        'idle': 0,
        'hover': 0.6,
        'press': 1,
      },
      motion: Motion.linear(80.ms),
      loop: LoopMode.none,
    );

    controller.playSequence<String>(
      sequence,
      atPhase: 'idle',
      onTransition: (transition) => transitions.add(transition.toString()),
      onLoop: loops.add,
      onSegmentStart: (index, from, to, _) =>
          events.add('start#$index:$from->$to'),
      onSegmentComplete: (index, from, to, _) =>
          events.add('end#$index:$from->$to'),
    );

    await tester.pump();
    await tester.pump(81.ms);
    await tester.pump();
    await tester.pump(81.ms);
    await tester.pump();

    expect(events, <String>[
      'start#0:idle->hover',
      'end#0:idle->hover',
      'start#1:hover->press',
      'end#1:hover->press',
    ]);
    expect(transitions, <String>[
      'PhaseSettled(idle)',
      'PhaseTransitioning(from: idle, to: hover)',
      'PhaseSettled(hover)',
      'PhaseTransitioning(from: hover, to: press)',
      'PhaseSettled(press)',
    ]);
    expect(loops, isEmpty);
    expect(controller.value, closeTo(1, 0.001));
    expect(controller.isAnimating, isFalse);
  });

  testWidgets('repeat ping-pong honors count and lifecycle hooks',
      (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final controller = AnimateController(
      vsync: tester,
      motion: Motion.linear(100.ms),
    );
    addTearDown(controller.dispose);

    final starts = <String>[];
    final completes = <String>[];
    final loops = <int>[];

    controller.repeat(
      reverse: true,
      count: 4,
      motion: Motion.linear(50.ms),
      onLoop: loops.add,
      onSegmentStart: (index, from, to, _) => starts
          .add('$index:${from.toStringAsFixed(1)}->${to.toStringAsFixed(1)}'),
      onSegmentComplete: (index, from, to, _) => completes
          .add('$index:${from.toStringAsFixed(1)}->${to.toStringAsFixed(1)}'),
    );

    await tester.pump();
    for (int i = 0; i < 4; i++) {
      await tester.pump(51.ms);
      await tester.pump();
    }

    expect(starts, <String>[
      '0:0.0->1.0',
      '1:1.0->0.0',
      '2:0.0->1.0',
      '3:1.0->0.0',
    ]);
    expect(completes, <String>[
      '0:0.0->1.0',
      '1:1.0->0.0',
      '2:0.0->1.0',
      '3:1.0->0.0',
    ]);
    expect(loops, <int>[1]);
    expect(controller.value, closeTo(0, 0.001));
    expect(controller.isAnimating, isFalse);
  });
}

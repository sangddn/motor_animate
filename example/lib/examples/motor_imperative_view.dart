import 'package:flutter/material.dart';
import 'package:motor_animate/motor_animate.dart';

class MotorImperativeView extends StatefulWidget {
  const MotorImperativeView({super.key});

  @override
  State<MotorImperativeView> createState() => _MotorImperativeViewState();
}

class _MotorImperativeViewState extends State<MotorImperativeView>
    with SingleTickerProviderStateMixin {
  late final AnimateController _controller;

  bool _springMode = true;
  double _target = 0.75;
  final List<String> _events = <String>[];

  @override
  void initState() {
    super.initState();
    _controller = AnimateController(
      vsync: this,
      motion: const Motion.smoothSpring(extraBounce: 0.15, snapToEnd: true),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyMode() {
    if (_springMode) {
      _controller.motion = const Motion.bouncySpring(
        extraBounce: 0.1,
        snapToEnd: true,
      );
    } else {
      _controller.motion = Motion.curved(700.ms, Curves.easeOutCubic);
    }
  }

  void _log(String message) {
    setState(() {
      _events.insert(0, message);
      if (_events.length > 10) _events.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    _applyMode();

    final card = Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6600D2FF),
            blurRadius: 24,
            spreadRadius: 2,
            offset: Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'MOTOR',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.2,
          fontSize: 34,
        ),
      ),
    )
        .animate(controller: _controller, autoPlay: false)
        .fadeIn(begin: 0.2, motion: Motion.curved(300.ms, Curves.easeOut))
        .scaleXY(
          begin: 0.82,
          end: 1.08,
          motion: Motion.curved(300.ms, Curves.easeOutBack),
        )
        .moveY(
          begin: 36,
          end: -10,
          motion: Motion.curved(300.ms, Curves.easeOutCubic),
        )
        .rotate(
          begin: -0.045,
          end: 0.04,
          motion: Motion.curved(300.ms, Curves.easeInOutSine),
        )
        .shimmer(motion: Motion.linear(1300.ms), delay: 250.ms, angle: 0.25);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Imperative Control + Motor Motion',
          style:
              TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1),
        ).animate().fadeIn(motion: Motion.linear(400.ms)).moveY(begin: 20),
        const SizedBox(height: 8),
        const Text(
          'This panel uses the same flutter_animate-style imperative flow, '
          'but the timeline is driven by motor simulations.',
          style: TextStyle(color: Color(0xFFB9C3CC)),
        ),
        const SizedBox(height: 24),
        Center(child: card),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Text(
            'value: ${_controller.value.toStringAsFixed(3)}   '
            'status: ${_controller.status.name}   '
            'animating: ${_controller.isAnimating}',
            style:
                const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _action('Play', () => _controller.forward(from: 0)),
            _action('Reverse', () => _controller.reverse(from: 1)),
            _action(
              'Loop x6',
              () => _controller.loop(
                reverse: true,
                count: 6,
                onLoop: (loop) => _log('loop#$loop'),
                onSegmentStart: (i, from, to, _) => _log(
                    'segment start #$i ${from.toStringAsFixed(2)}→${to.toStringAsFixed(2)}'),
                onSegmentComplete: (i, from, to, _) => _log(
                    'segment end #$i ${from.toStringAsFixed(2)}→${to.toStringAsFixed(2)}'),
              ),
            ),
            _action(
              'Phase Sequence',
              () => _controller.playSequence<String>(
                MotionSequence.states(
                  const <String, double>{
                    'idle': 0.0,
                    'hover': 0.6,
                    'press': 1.0,
                  },
                  motion: const Motion.snappySpring(extraBounce: 0.05),
                  loop: LoopMode.pingPong,
                ),
                atPhase: 'idle',
                onTransition: (transition) => _log('phase $transition'),
                onLoop: (loop) => _log('phase loop#$loop'),
                onSegmentStart: (i, from, to, motion) =>
                    _log('phase start #$i $from→$to ${motion.runtimeType}'),
                onSegmentComplete: (i, from, to, motion) =>
                    _log('phase end #$i $from→$to ${motion.runtimeType}'),
              ),
            ),
            _action('Stop', () => _controller.stop()),
            _action('Reset', _controller.reset),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('Motion mode:'),
            const SizedBox(width: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: true, label: Text('Spring')),
                ButtonSegment<bool>(value: false, label: Text('Curve')),
              ],
              selected: {_springMode},
              onSelectionChanged: (value) {
                setState(() => _springMode = value.first);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Target'),
            Expanded(
              child: Slider(
                value: _target,
                min: 0,
                max: 1,
                divisions: 100,
                label: _target.toStringAsFixed(2),
                onChanged: (value) => setState(() => _target = value),
              ),
            ),
            SizedBox(
              width: 90,
              child: Text(
                _target.toStringAsFixed(2),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        _action(
          'Animate To Target',
          () {
            if (_springMode) {
              _controller.animateTo(_target);
            } else {
              _controller.animateTo(
                _target,
                motion: Motion.curved(600.ms, Curves.easeInOutCubic),
              );
            }
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Lifecycle Events',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF252A31),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final event in _events)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    event,
                    style: const TextStyle(
                      color: Color(0xFFB4C2D0),
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              if (_events.isEmpty)
                const Text(
                  'Trigger loop or phase sequence to see segment hooks.',
                  style: TextStyle(color: Color(0xFF8B97A3), fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _action(String label, VoidCallback onPressed) {
    return FilledButton.tonal(onPressed: onPressed, child: Text(label));
  }
}

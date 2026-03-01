// This is a playground view to make it easy to play around with Flutter Animate.

import 'package:flutter/material.dart';
import 'package:motor_animate/motor_animate.dart';

class PlaygroundView extends StatelessWidget {
  const PlaygroundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        child: const Text("Playground 🛝")
            .animate()
            .slideY(motion: Motion.curved(900.ms, Curves.easeOutCubic))
            .fadeIn(),
      ),
    );
  }
}

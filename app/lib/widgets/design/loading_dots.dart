import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class LoadingDots extends StatefulWidget {
  final Color color;
  final double size;

  const LoadingDots({
    super.key,
    this.color = AppColors.statusOnline, // Default to Online Blue
    this.size = 10.0,
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 5, // 3 dots + spacing
      height: widget.size * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              // Staggered sine wave
              final delay = index * 0.2;
              final t = (_controller.value + delay) % 1.0;
              final y = -4.0 * (0.5 - (0.5 - t).abs()); // Simple bounce approximation? No.
              // Use Sine
              // sin(2*pi*t) -> -1 to 1.
              // We want bounce up.
              final offset = -8.0 * (1.0 - (2 * (0.5 - t).abs())); // Triangle wave 0->1->0
              
              // Better: sin
              // sin(2 * pi * t)
              // We want it to just jump up once per cycle?
              // Let's use standard sin wave for breathing feel.
              
              final double shift = 6.0 * (-0.5 + 0.5 * (1.0 + (t * 6.28).sin())); // 0 to 6? No.
              // Simple: sin(2*pi * (t - delay))
              
              final double value = (2 * 3.14159 * (t)).sin();
              final double dy = value < 0 ? 0 : -value * 6; // Only bounce up

              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

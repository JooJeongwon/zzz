import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleMinValue;
  final Duration duration;
  final ScrollController? scrollController; // To detect scrolling vs tapping

  const ScaleTap({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleMinValue = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.scrollController,
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      upperBound: 1.0, // We will reverse from 1.0 to scaleMinValue
      lowerBound: 0.0,
      value: 0.0, 
    );
    
    // We want to animate FROM 1.0 TO scaleMinValue
    // So when controller goes 0->1, scale goes 1.0 -> scaleMinValue
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    _isPressed = true;
    _controller.forward();
    HapticFeedback.lightImpact(); // Haptic feedback
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed == null) return;
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // If no callback, just return child
    if (widget.onPressed == null) return widget.child;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque, // Allows hit testing on the child
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // controller.value: 0.0 (idle) -> 1.0 (pressed)
          // scale: 1.0 -> scaleMinValue
          final scale = 1.0 - (_controller.value * (1.0 - widget.scaleMinValue));
          return Transform.scale(
            scale: scale,
            child: widget.child,
          );
        },
      ),
    );
  }
}

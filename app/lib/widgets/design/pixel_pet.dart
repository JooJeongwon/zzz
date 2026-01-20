import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_status.dart';
import '../../theme/colors.dart';

class PixelPet extends StatefulWidget {
  final UserStatus status;
  final double size;

  const PixelPet({
    super.key,
    required this.status,
    this.size = 150.0,
  });

  @override
  State<PixelPet> createState() => _PixelPetState();
}

class _PixelPetState extends State<PixelPet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathingAnimation;
  Timer? _blinkTimer;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    // Breathing: 3-second cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _breathingAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
    
    // Random Blink
    _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(Duration(milliseconds: 2000 + (3000 * (DateTime.now().millisecond / 1000)).toInt()), () {
        if (mounted) {
          setState(() => _isBlinking = true);
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              setState(() => _isBlinking = false);
              _scheduleBlink();
            }
          });
        }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _breathingAnimation.value),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _PixelPetPainter(widget.status, _isBlinking),
          ),
        );
      },
    );
  }
}

class _PixelPetPainter extends CustomPainter {
  final UserStatus status;
  final bool isBlinking;

  _PixelPetPainter(this.status, this.isBlinking);

  Color get _primaryColor {
    switch (status) {
      case UserStatus.SLEEP:
        return AppColors.statusSleep;
      case UserStatus.STUDY:
        return AppColors.statusStudy;
      case UserStatus.BUSY:
        return AppColors.statusBusy;
      case UserStatus.ONLINE:
      default:
        return AppColors.statusOnline;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _primaryColor
      ..style = PaintingStyle.fill;

    final double pixelSize = size.width / 16;
    
    // Draw Base Body (Simple Round Shape in 16x16 grid)
    // Center approx at 8,8. Radius 6.
    // Simplifying to a few rects for pixel look
    
    // Main Body
    for (int y = 4; y < 14; y++) {
      for (int x = 4; x < 12; x++) {
        // Corners cut
        if ((x == 4 || x == 11) && (y == 4 || y == 13)) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize, pixelSize),
          paint,
        );
      }
    }
    
    // Ears
    canvas.drawRect(Rect.fromLTWH(4 * pixelSize, 3 * pixelSize, pixelSize, pixelSize), paint);
    canvas.drawRect(Rect.fromLTWH(11 * pixelSize, 3 * pixelSize, pixelSize, pixelSize), paint);

    // Face Details
    final facePaint = Paint()..color = Colors.white; // Simple contrast
    
    if (status == UserStatus.SLEEP) {
      // Closed Eyes (Lines)
      canvas.drawRect(Rect.fromLTWH(6 * pixelSize, 7 * pixelSize, 1 * pixelSize, 1 * pixelSize), facePaint);
      canvas.drawRect(Rect.fromLTWH(9 * pixelSize, 7 * pixelSize, 1 * pixelSize, 1 * pixelSize), facePaint);
      
      // Zzz (floating)
      final zPaint = Paint()..color = AppColors.statusSleep;
      // Just a simple dot representation for Zzz for now
      canvas.drawRect(Rect.fromLTWH(13 * pixelSize, 2 * pixelSize, pixelSize, pixelSize), zPaint);
      canvas.drawRect(Rect.fromLTWH(14 * pixelSize, 1 * pixelSize, pixelSize, pixelSize), zPaint);
    } else if (status == UserStatus.STUDY || status == UserStatus.BUSY) {
      // Glasses (Line across)
      canvas.drawRect(Rect.fromLTWH(5 * pixelSize, 7 * pixelSize, 6 * pixelSize, 1 * pixelSize), facePaint);
    } else {
      // Online / Smile
       // Eyes
      if (isBlinking) {
         // Closed eyes for blink
         canvas.drawRect(Rect.fromLTWH(6 * pixelSize, 7 * pixelSize, pixelSize, pixelSize), paint); // Masking with primary color would be wrong if facePaint is white.
         // Actually we need to draw "Line" eyes instead of "Block" eyes when blinking
         // Or just skipping the white eyes drawing will make them "color of body" which might look like closed if we draw a line?
         // Let's draw a line of body color (or darker?) NO, usually closing eyes means drawing a line.
         
         // Let's use body color to 'erase' white, then draw a line.
         // But here facePaint is white. 
         // Strategy: Draw eyes only if NOT blinking. If blinking, draw line.
         final blinkPaint = Paint()..color = Colors.black.withOpacity(0.2); // Darker line? Or just simple line.
         // Simpler: Just don't draw the white blocks. 
         // And maybe draw a thin line?
         canvas.drawRect(Rect.fromLTWH(6 * pixelSize, 8 * pixelSize, pixelSize, 1), blinkPaint);
         canvas.drawRect(Rect.fromLTWH(9 * pixelSize, 8 * pixelSize, pixelSize, 1), blinkPaint);
      } else {
        canvas.drawRect(Rect.fromLTWH(6 * pixelSize, 7 * pixelSize, pixelSize, pixelSize), facePaint);
        canvas.drawRect(Rect.fromLTWH(9 * pixelSize, 7 * pixelSize, pixelSize, pixelSize), facePaint);
      }
      // Mouth
      canvas.drawRect(Rect.fromLTWH(7 * pixelSize, 10 * pixelSize, 2 * pixelSize, pixelSize), facePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelPetPainter oldDelegate) {
    return oldDelegate.status != status || oldDelegate.isBlinking != isBlinking;
  }

}

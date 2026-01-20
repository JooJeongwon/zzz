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

  @override
  void initState() {
    super.initState();
    // Breathing: 3-second cycle, moving up and down slightly (5px)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Half cycle is 1.5s -> Full 3s
    );

    _breathingAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
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
            painter: _PixelPetPainter(widget.status),
          ),
        );
      },
    );
  }
}

class _PixelPetPainter extends CustomPainter {
  final UserStatus status;

  _PixelPetPainter(this.status);

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
      canvas.drawRect(Rect.fromLTWH(6 * pixelSize, 7 * pixelSize, pixelSize, pixelSize), facePaint);
      canvas.drawRect(Rect.fromLTWH(9 * pixelSize, 7 * pixelSize, pixelSize, pixelSize), facePaint);
      // Mouth
      canvas.drawRect(Rect.fromLTWH(7 * pixelSize, 10 * pixelSize, 2 * pixelSize, pixelSize), facePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

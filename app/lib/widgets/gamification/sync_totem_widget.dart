import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_status.dart';

class SyncTotemWidget extends StatefulWidget {
  final DateTime? syncStartTime;
  final UserStatus status;

  const SyncTotemWidget({
    super.key, 
    this.syncStartTime, 
    this.status = UserStatus.UNKNOWN,
  });

  @override
  State<SyncTotemWidget> createState() => _SyncTotemWidgetState();
}

class _SyncTotemWidgetState extends State<SyncTotemWidget> {
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant SyncTotemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.syncStartTime != oldWidget.syncStartTime) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.syncStartTime == null) {
      if (mounted) setState(() => _duration = Duration.zero);
      return;
    }

    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDuration());
  }

  void _updateDuration() {
    if (widget.syncStartTime == null || !mounted) return;
    setState(() {
      _duration = DateTime.now().difference(widget.syncStartTime!);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.syncStartTime == null) return const SizedBox.shrink();

    // 1 hour to reach 50% screen height as an example base
    final double screenHeight = MediaQuery.of(context).size.height;
    final double fillPercentage = (_duration.inSeconds / 3600.0).clamp(0.0, 1.0);
    final double height = (screenHeight * 0.4 * fillPercentage) + 80; 

    final color = widget.status.color;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             // Duration Text
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.9),
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                   BoxShadow(
                     color: color.withOpacity(0.3),
                     blurRadius: 10,
                   )
                 ]
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Icon(Icons.timer, size: 16, color: color),
                   const SizedBox(width: 4),
                   Text(
                     _formatDuration(_duration),
                     style: TextStyle(
                       color: color,
                       fontWeight: FontWeight.bold,
                       fontSize: 14,
                     ),
                   ),
                 ],
               ),
             ),
             const SizedBox(height: 12),
             
             // Totem Body
             Stack(
               alignment: Alignment.bottomCenter,
               children: [
                 // Glow
                 Container(
                   width: 100,
                   height: height,
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       begin: Alignment.bottomCenter,
                       end: Alignment.topCenter,
                       colors: [
                         color.withOpacity(0.4),
                         color.withOpacity(0.0),
                       ],
                     ),
                   ),
                 ),
                 // Core Pillar
                 AnimatedContainer(
                   duration: const Duration(seconds: 1),
                   width: 40,
                   height: height,
                   decoration: BoxDecoration(
                     color: color.withOpacity(0.2),
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                     border: Border.all(color: color.withOpacity(0.5), width: 2),
                     boxShadow: [
                       BoxShadow(
                         color: color.withOpacity(0.2),
                         blurRadius: 15,
                         spreadRadius: 2,
                       )
                     ]
                   ),
                 ),
                 // Floating Particles or Decor (Simplified for now)
               ],
             ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes";
  }
}

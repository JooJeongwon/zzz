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
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _updateDuration()); // Update every minute is enough for display
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

    // Matte, Flat Design (No Gradient, No Shadow)
    final color = widget.status.color;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Flat tint background
        borderRadius: BorderRadius.circular(20), // Soft Corner
        border: Border.all(
          color: color.withOpacity(0.3), // Subtle border
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            _formatDuration(_duration),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 60) {
      return "${d.inMinutes}분째";
    } else {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      return "${hours}시간 ${minutes}분째";
    }
  }
}

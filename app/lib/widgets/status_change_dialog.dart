import 'package:flutter/material.dart';
import '../models/user_status.dart';

class StatusChangeDialog extends StatefulWidget {
  final UserStatus currentStatus;
  final Function(UserStatus, int?) onStatusSelected;

  const StatusChangeDialog({
    Key? key,
    required this.currentStatus,
    required this.onStatusSelected,
  }) : super(key: key);

  @override
  _StatusChangeDialogState createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<StatusChangeDialog> {
  late UserStatus _selectedStatus;
  int? _selectedDuration; // null means "Manual"

  final List<int?> _durationOptions = [
    null, // 직접 해제
    30,
    60,
    120,
    240,
    480, // 8 hours
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  String _getDurationLabel(int? minutes) {
    if (minutes == null) return "직접 해제할 때까지";
    if (minutes < 60) return "$minutes분";
    final hours = minutes ~/ 60;
    return "$hours시간";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '상태 변경',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatusButton(UserStatus.ONLINE, Icons.sentiment_satisfied_alt, Colors.green),
                _buildStatusButton(UserStatus.SLEEP, Icons.bedtime, Colors.indigo),
                _buildStatusButton(UserStatus.STUDY, Icons.menu_book, Colors.orange),
                _buildStatusButton(UserStatus.BUSY, Icons.work, Colors.red),
              ],
            ),
            
            if (_selectedStatus != UserStatus.ONLINE) ...[
              const SizedBox(height: 24),
              const Text(
                "지속 시간",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _durationOptions.map((duration) {
                  final isSelected = _selectedDuration == duration;
                  return ChoiceChip(
                    label: Text(_getDurationLabel(duration)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDuration = duration;
                        });
                      }
                    },
                    selectedColor: Colors.blue[100],
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue[800] : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onStatusSelected(_selectedStatus, _selectedDuration);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('변경하기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(UserStatus status, IconData icon, Color color) {
    final isSelected = status == _selectedStatus;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
          // Reset duration if switching to ONLINE (though hidden, good to be clean)
          if (status == UserStatus.ONLINE) {
            _selectedDuration = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              status.label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

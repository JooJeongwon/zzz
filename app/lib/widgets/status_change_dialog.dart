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
      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(40)),
      backgroundColor: AppColors.surfaceDay,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change Status',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatusButton(UserStatus.ONLINE),
                _buildStatusButton(UserStatus.SLEEP),
                _buildStatusButton(UserStatus.STUDY),
                _buildStatusButton(UserStatus.BUSY),
              ],
            ),
            
            if (_selectedStatus != UserStatus.ONLINE) ...[
              const SizedBox(height: 24),
              Text(
                "Duration",
                style: Theme.of(context).textTheme.bodyLarge,
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
                    selectedColor: _selectedStatus.color.withOpacity(0.2),
                    backgroundColor: AppColors.backgroundDay,
                    side: isSelected 
                      ? BorderSide(color: _selectedStatus.color) 
                      : const BorderSide(color: AppColors.borderDay),
                    labelStyle: TextStyle(
                      color: isSelected ? _selectedStatus.color : AppColors.textPrimaryDay,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDay)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onStatusSelected(_selectedStatus, _selectedDuration);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedStatus.color,
                    foregroundColor: Colors.white,
                    shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(24)), // Squircle button too
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(UserStatus status) {
    final isSelected = status == _selectedStatus;
    final color = status.color;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
          if (status == UserStatus.ONLINE) {
            _selectedDuration = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: isSelected 
              ? null
              : Border.all(color: AppColors.borderDay, width: 1.5),
          borderRadius: BorderRadius.circular(20),
          // No shadow
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status.icon, 
              size: 32, 
              color: isSelected ? Colors.white : color
            ),
            const SizedBox(height: 8),
            Text(
              status.label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimaryDay,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

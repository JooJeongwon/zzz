import 'user_status.dart';

class PartnerStatus {
  final int userId;
  final String nickname;
  final UserStatus status;
  final DateTime? lastActiveAt;
  final int? batteryLevel;

  PartnerStatus({
    required this.userId,
    required this.nickname,
    required this.status,
    this.lastActiveAt,
    this.batteryLevel,
  });

  factory PartnerStatus.fromJson(Map<String, dynamic> json) {
    return PartnerStatus(
      userId: json['userId'],
      nickname: json['nickname'],
      status: UserStatus.fromString(json['status']),
      lastActiveAt: json['lastActiveAt'] != null 
          ? DateTime.tryParse(json['lastActiveAt']) 
          : null,
      batteryLevel: json['batteryLevel'],
    );
  }
}

class CoupleInvite {
  final String code;
  final int expiresSeconds;

  CoupleInvite({required this.code, required this.expiresSeconds});

  factory CoupleInvite.fromJson(Map<String, dynamic> json) {
    return CoupleInvite(
      code: json['code'],
      expiresSeconds: json['expiresSeconds'],
    );
  }
}

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../core/result.dart';
import '../models/partner_status.dart';
import '../models/user_status.dart';
import '../providers/api_provider.dart';

class HomeState {
  final bool isLoading;
  final PartnerStatus? partnerStatus;
  final UserStatus myStatus;
  final String? error;
  final String serviceStatusMessage;
  final bool isConnectionError;

  HomeState({
    this.isLoading = true,
    this.partnerStatus,
    this.myStatus = UserStatus.ONLINE,
    this.error,
    this.serviceStatusMessage = 'Service not started',
    this.isConnectionError = false,
  });

  HomeState copyWith({
    bool? isLoading,
    PartnerStatus? partnerStatus,
    UserStatus? myStatus,
    String? error,
    String? serviceStatusMessage,
    bool? isConnectionError,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      partnerStatus: partnerStatus ?? this.partnerStatus,
      myStatus: myStatus ?? this.myStatus,
      error: error, // Nullable update logic is tricky, here if passed it updates, if not it keeps. 
                    // Actually usually we want to clear error. 
                    // Let's assume if error is passed as null it remains null? 
                    // No, for error clearing we might need explicit null.
                    // For simplicity: new value overrides old.
      serviceStatusMessage: serviceStatusMessage ?? this.serviceStatusMessage,
      isConnectionError: isConnectionError ?? this.isConnectionError,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref ref;
  Timer? _timer;
  static const platform = MethodChannel('com.joo.zzz.app/heartbeat');

  HomeViewModel(this.ref) : super(HomeState()) {
    _init();
  }

  void _init() {
    fetchPartnerStatus();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchPartnerStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchPartnerStatus() async {
    final result = await ref.read(apiServiceProvider).getPartnerStatus();
    
    if (!mounted) return;

    switch (result) {
      case Success(data: final status):
        state = state.copyWith(
          isLoading: false,
          partnerStatus: status,
          isConnectionError: false,
          error: null,
        );
        if (status != null) {
          _updateWidget(status);
        }
        break;
      case Failure(message: final msg, exception: final exc):
        // Check for 403 or specific errors if needed
        if (msg.contains('403')) {
           _timer?.cancel();
           state = state.copyWith(error: 'SESSION_EXPIRED');
        } else {
           // If we have data, we might want to keep showing it
           state = state.copyWith(
             isLoading: false,
             isConnectionError: state.partnerStatus == null, // Only error if no data
           );
        }
        break;
    }
  }

  Future<void> updateMyStatus(UserStatus status, int? duration) async {
    // Optimistic update
    final oldStatus = state.myStatus;
    state = state.copyWith(myStatus: status);

    final result = await ref.read(apiServiceProvider).updateStatus(status, durationMinutes: duration);

    if (result is Failure) {
      // Revert
      state = state.copyWith(myStatus: oldStatus, error: 'UPDATE_FAILED');
    }
  }

  Future<void> startHeartbeatService() async {
    String message;
    try {
      final api = ref.read(apiServiceProvider);
      final userId = await api.getUserId();
      final token = await api.getToken();
      
      if (userId == null || token == null) {
        message = "Error: User ID or Token not found.";
      }
      else {
        final String result = await platform.invokeMethod('startHeartbeat', {
          'userId': userId,
          'accessToken': token,
          'baseUrl': api.baseUrl,
        });
        message = 'Success: $result';
      }
    } on PlatformException catch (e) {
      message = "Failed to start service: '${e.message}'.";
    }

    state = state.copyWith(serviceStatusMessage: message);
  }

  Future<void> logout() async {
    await ref.read(apiServiceProvider).logout();
    _timer?.cancel();
  }

  Future<void> _updateWidget(PartnerStatus partner) async {
    try {
      const groupId = 'group.com.joo.zzz';
      await HomeWidget.setAppGroupId(groupId);
      await HomeWidget.saveWidgetData<String>('title', partner.nickname);
      await HomeWidget.saveWidgetData<String>('status', partner.status.label);
      await HomeWidget.saveWidgetData<String>('updatedAt', _formatTime(DateTime.now()));
      await HomeWidget.updateWidget(
        name: 'StatusWidgetProvider',
        androidName: 'StatusWidgetProvider',
        iOSName: 'ZZZWidget',
      );
    } catch (e) {
      // Ignore widget update errors
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    return DateFormat('M월 d일 a h:mm', 'ko_KR').format(time);
  }
}

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(ref);
});

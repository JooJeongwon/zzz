import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../core/result.dart';
import '../core/app_error.dart';
import '../models/partner_status.dart';
import '../models/user_status.dart';
import '../providers/api_provider.dart';
import '../services/native_bridge_service.dart';

class HomeState {
  final bool isLoading;
  final PartnerStatus? partnerStatus;
  final UserStatus myStatus;
  final AppError? error;
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
    AppError? error,
    String? serviceStatusMessage,
    bool? isConnectionError,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      partnerStatus: partnerStatus ?? this.partnerStatus,
      myStatus: myStatus ?? this.myStatus,
      error: error,
      serviceStatusMessage: serviceStatusMessage ?? this.serviceStatusMessage,
      isConnectionError: isConnectionError ?? this.isConnectionError,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref ref;
  Timer? _timer;

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
        // Logging error (placeholder for Crashlytics)
        print("Fetch Error: $msg"); 

        if (msg.contains('403')) {
           _timer?.cancel();
           state = state.copyWith(error: const SessionExpiredError());
        } else {
           state = state.copyWith(
             isLoading: false,
             isConnectionError: state.partnerStatus == null,
             error: state.partnerStatus == null ? NetworkError(msg) : null,
           );
        }
        break;
    }
  }

  Future<void> updateMyStatus(UserStatus status, int? duration) async {
    final oldStatus = state.myStatus;
    state = state.copyWith(myStatus: status);

    final result = await ref.read(apiServiceProvider).updateStatus(status, durationMinutes: duration);

    if (result is Failure) {
      state = state.copyWith(myStatus: oldStatus, error: const UpdateFailedError());
    }
  }

  Future<void> startHeartbeatService() async {
    String message;
    final api = ref.read(apiServiceProvider);
    final userId = await api.getUserId();
    final token = await api.getToken();
    
    if (userId == null || token == null) {
      message = "Error: User ID or Token not found.";
    }
    else {
      message = await ref.read(nativeBridgeServiceProvider).startHeartbeat(userId.toString(), token, api.baseUrl);
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
    } catch (e, stack) {
      print("Widget Update Failed: $e\n$stack"); // Improved logging
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

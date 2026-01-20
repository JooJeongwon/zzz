import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';
import '../models/partner_status.dart';
import '../models/user_status.dart';
import '../services/api_service.dart';
import '../theme/theme_controller.dart';
import '../widgets/status_change_dialog.dart';
import 'login_screen.dart';
import 'connect_couple_screen.dart';
import 'chat_screen.dart';
import '../widgets/design/clean_card.dart';
import '../widgets/design/pixel_pet.dart';
import '../theme/colors.dart';
import '../widgets/design/loading_dots.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.joo.zzz.app/heartbeat');
  
  PartnerStatus? _partnerStatus;
  bool _isLoading = true;
  bool _isConnectionError = false; // New state for error handling
  Timer? _timer;
  String _serviceStatusMessage = 'Service not started';
  UserStatus _myStatus = UserStatus.ONLINE;

  @override
  void initState() {
    super.initState();
    _fetchPartnerStatus();
    // Poll every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchPartnerStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      debugPrint("Error updating widget: $e");
    }
  }

  Future<void> _fetchPartnerStatus() async {
    try {
      final status = await ApiService.getPartnerStatus();
      
      if (mounted) {
        setState(() {
          _isConnectionError = false;
          if (status != null) {
              _partnerStatus = status;
              _updateWidget(status);
              
              if (status.status == UserStatus.SLEEP) {
                ThemeController.setDark();
              } else {
                ThemeController.setLight();
              }
          } else {
            // Success but no partner (status is null)
            _partnerStatus = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('403')) {
          _timer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('세션이 만료되었습니다. 다시 로그인해주세요.')),
          );
          _logout();
        } else {
          // If we have data, keep showing it but warn user.
          // If we don't have data, show error screen.
          if (_partnerStatus != null) {
             // Optional: Show a subtle indicator or snackbar (throttled)
             // debugPrint("Connection lost, using stale data");
          } else {
             setState(() {
               _isConnectionError = true;
             });
          }
        }
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateMyStatus(UserStatus status, int? duration) async {
    setState(() => _myStatus = status); // Optimistic update

    final success = await ApiService.updateStatus(status, durationMinutes: duration);

    if (!mounted) return;

    if (!success) {
       // Revert or show error
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('상태 변경에 실패했습니다.')));
    }
  }

  Future<void> _startHeartbeatService() async {
    String message;
    try {
      final userId = await ApiService.getUserId();
      final token = await ApiService.getToken();
      
      if (userId == null || token == null) {
        message = "Error: User ID or Token not found.";
      }
      else {
        final String result = await platform.invokeMethod('startHeartbeat', {
          'userId': userId,
          'accessToken': token,
          'baseUrl': ApiService.baseUrl,
        });
        message = 'Success: $result';
      }
    }
    on PlatformException catch (e) {
      message = "Failed to start service: '${e.message}'.";
    }

    setState(() {
      _serviceStatusMessage = message;
    });
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZZZ'),
        actions: [
          IconButton(icon: const Icon(Icons.link), onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectCoupleScreen()));
          }),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: LoadingDots()) 
        : _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startHeartbeatService,
        tooltip: 'Start Background Service',
        child: const Icon(Icons.favorite),
      ),
    );
  }

  Widget _buildBody() {
    if (_isConnectionError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: AppColors.textSecondaryDay),
            const SizedBox(height: 16),
            const Text(
              '네트워크 연결 상태가 좋지 않습니다.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchPartnerStatus();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_partnerStatus == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PixelPet(status: UserStatus.UNKNOWN, size: 120),
            const SizedBox(height: 24),
            const Text(
              '연결된 파트너가 없습니다.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDay),
            ),
            const SizedBox(height: 8),
            const Text(
              '초대 코드를 공유하여\n커플을 연결해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryDay),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectCoupleScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusOnline,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: const Text('파트너 연결하기'),
              ),
            ),
          ],
        ),
      );
    }

    final partner = _partnerStatus!;
    final color = partner.status.color;

    return Column(
      children: [
        // Partner Area (Top 55%)
        Expanded(
          flex: 55,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceDay,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              border: Border.all(color: AppColors.borderDay, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pixel Pet
                Hero(
                  tag: 'partner_pet',
                  child: PixelPet(status: partner.status, size: 180),
                ),
                const SizedBox(height: 24),
                // Partner Info
                Text(
                  partner.nickname,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  partner.status.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (partner.lastActiveAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '마지막 활동:${_formatTime(partner.lastActiveAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (partner.batteryLevel != null)
                   Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.battery_std, size: 16, color: AppColors.textSecondaryDay),
                        Text(
                          '${partner.batteryLevel}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                       partnerId: partner.userId,
                       partnerName: partner.nickname,
                     )));
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text("채팅"),
                ),
              ],
            ),
          ),
        ),

        // My Area (Bottom 45%) - Floating Control
        Expanded(
          flex: 45,
          child: Container(
             padding: const EdgeInsets.all(24),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 CleanCard(
                   onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => StatusChangeDialog(
                          currentStatus: _myStatus,
                          onStatusSelected: _updateMyStatus,
                        ),
                      );
                   },
                   padding: const EdgeInsets.all(20),
                   child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: _myStatus.color.withOpacity(0.1),
                           shape: BoxShape.circle,
                         ),
                         child: Icon(_myStatus.icon, color: _myStatus.color, size: 36),
                       ),
                       const SizedBox(width: 20),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text('나의 상태', style: Theme.of(context).textTheme.bodySmall),
                           const SizedBox(height: 4),
                           Text(
                             _myStatus.label,
                             style: Theme.of(context).textTheme.titleLarge?.copyWith(
                               color: _myStatus.color
                             ),
                           ),
                         ],
                       ),
                       const Spacer(),
                       const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondaryDay, size: 20),
                     ],
                   ),
                 ),
                 const SizedBox(height: 20),
                 const Text(
                   "상태를 변경하려면 탭하세요",
                   style: TextStyle(color: AppColors.textSecondaryDay),
                 ),
                 if (_serviceStatusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(_serviceStatusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
               ],
             ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';

    return DateFormat('M월 d일 a h:mm', 'ko_KR').format(time);
  }
}
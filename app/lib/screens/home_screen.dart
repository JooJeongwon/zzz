import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/home_view_model.dart';
import '../models/user_status.dart';
import '../theme/theme_controller.dart';
import '../widgets/status_change_dialog.dart';
import '../core/app_error.dart';
import 'login_screen.dart';
import 'connect_couple_screen.dart';
import 'chat_screen.dart';
import '../widgets/design/clean_card.dart';
import '../widgets/design/pixel_pet.dart';
import '../theme/colors.dart';
import '../widgets/design/loading_dots.dart';
import '../widgets/gamification/sync_totem_widget.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  
  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Theme.of(context).canvasColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("로그아웃", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text("정말 로그아웃 하시겠습니까?", textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   TextButton(
                     onPressed: () => Navigator.pop(context, false),
                     child: const Text("취소", style: TextStyle(color: AppColors.textSecondaryDay)),
                   ),
                   const SizedBox(width: 8),
                   ElevatedButton(
                     onPressed: () => Navigator.pop(context, true),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.textPrimaryDay,
                       foregroundColor: Colors.white,
                       shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(20)),
                     ),
                     child: const Text("로그아웃"),
                   ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    await ref.read(homeViewModelProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    // Listen to state changes for side effects
    ref.listen(homeViewModelProvider, (previous, next) {
      if (next.error is SessionExpiredError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('세션이 만료되었습니다. 다시 로그인해주세요.')),
        );
        _logout();
      } else if (next.error is UpdateFailedError) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상태 업데이트에 실패했습니다. 다시 시도해주세요.')),
        );
      } else if (next.error != null && next.error != previous?.error) {
         // Handle other errors if needed
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZZZ'),
        actions: [
          IconButton(icon: const Icon(Icons.link), onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => ConnectCoupleScreen(isConnected: state.partnerStatus != null)));
          }),
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark 
              ? Icons.dark_mode 
              : Icons.light_mode),
            onPressed: ThemeController.toggleTheme,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: state.isLoading 
        ? const Center(child: LoadingDots()) 
        : _buildBody(state, viewModel),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.startHeartbeatService,
        tooltip: 'Start Background Service',
        child: const Icon(Icons.favorite),
      ),
    );
  }

  Widget _buildBody(HomeState state, HomeViewModel viewModel) {
    if (state.isConnectionError) {
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
                viewModel.fetchPartnerStatus();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (state.partnerStatus == null) {
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

    final partner = state.partnerStatus!;
    final color = partner.status.color;

    return Stack(
      children: [
        // Background Layer: Sync Totem
        SyncTotemWidget(
          syncStartTime: partner.syncStartTime,
          status: partner.status,
        ),

        // Foreground Layer: Content
        Column(
          children: [
            // Partner Area (Top 55%)
            Expanded(
              flex: 55,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.85), // Semi-transparent
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderNight
                        : AppColors.borderDay,
                    width: 1.5,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Pixel Pet
                  Hero(
                    tag: 'partner_pet',
                    child: PixelPet(
                      status: partner.status, 
                      size: 180,
                      level: partner.coupleLevel,
                      decorationType: partner.decorationType,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Partner Info
                  Text(
                    partner.nickname,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statusOnline.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Lv. ${partner.coupleLevel}",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.statusOnline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        const Icon(Icons.battery_std, size: 16, color: AppColors.textSecondaryDay),
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
                  const SizedBox(height: 24),
                ],
              ),
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
                          currentStatus: state.myStatus,
                          onStatusSelected: viewModel.updateMyStatus,
                        ),
                      );
                   },
                   padding: const EdgeInsets.all(20),
                   child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: state.myStatus.color.withOpacity(0.1),
                           shape: BoxShape.circle,
                         ),
                         child: Icon(state.myStatus.icon, color: state.myStatus.color, size: 36),
                       ),
                       const SizedBox(width: 20),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text('나의 상태', style: Theme.of(context).textTheme.bodySmall),
                           const SizedBox(height: 4),
                           Text(
                             state.myStatus.label,
                             style: Theme.of(context).textTheme.titleLarge?.copyWith(
                               color: state.myStatus.color
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
                 if (state.serviceStatusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(state.serviceStatusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
               ],
             ),
          ),
        ),
      ],
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

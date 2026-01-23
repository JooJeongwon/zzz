import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';
import '../core/result.dart';
import 'home_screen.dart';
import '../widgets/design/clean_card.dart';
import '../theme/colors.dart';

class ConnectCoupleScreen extends ConsumerStatefulWidget {
  final bool isConnected;

  const ConnectCoupleScreen({super.key, this.isConnected = false});

  @override
  ConsumerState<ConnectCoupleScreen> createState() => _ConnectCoupleScreenState();
}

class _ConnectCoupleScreenState extends ConsumerState<ConnectCoupleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Invite Tab
  String? _inviteCode;
  bool _isGenerating = false;

  // Connect Tab
  final _codeController = TextEditingController();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() => _isGenerating = true);
    final result = await ref.read(apiServiceProvider).createInviteCode();
    
    if (!mounted) return;

    setState(() {
      _isGenerating = false;
      if (result is Success) {
        _inviteCode = (result as Success).data?.code;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('코드 생성 실패')),
        );
      }
    });
  }

  Future<void> _connect() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isConnecting = true);
    final result = await ref.read(apiServiceProvider).connectCouple(code);
    
    if (!mounted) return;
    setState(() => _isConnecting = false);

    switch (result) {
      case Success(data: final success):
        if (success) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연결 실패. 코드를 확인해주세요.')),
          );
        }
        break;
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연결 오류: $msg')),
        );
        break;
    }
  }

  Future<void> _disconnect() async {
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
              const Text("연결 끊기", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text("정말로 파트너와의 연결을 끊으시겠습니까?\n이 작업은 되돌릴 수 없습니다.", textAlign: TextAlign.center),
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
                       backgroundColor: AppColors.statusBusy, // Red
                       foregroundColor: Colors.white,
                       shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(20)),
                     ),
                     child: const Text("끊기"),
                   ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isConnecting = true); // reuse loading state
    final result = await ref.read(apiServiceProvider).disconnectCouple();
    
    if (!mounted) return;
    setState(() => _isConnecting = false);

    switch (result) {
      case Success(data: final success):
        if (success) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연결이 해제되었습니다.')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('연결 해제 실패. 다시 시도해주세요.')),
           );
        }
        break;
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $msg')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isConnected ? '파트너 관리' : '파트너 연결'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? AppColors.textPrimaryNight : AppColors.textPrimaryDay),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: widget.isConnected 
          ? null 
          : TabBar(
              controller: _tabController,
              labelColor: AppColors.statusOnline,
              unselectedLabelColor: AppColors.textSecondaryDay,
              indicatorColor: AppColors.statusOnline,
              tabs: const [
                Tab(text: '내 초대 코드'),
                Tab(text: '코드 입력'),
              ],
            ),
      ),
      body: widget.isConnected 
        ? _buildDisconnectView()
        : TabBarView(
            controller: _tabController,
            children: [
              _buildInviteView(),
              _buildEnterCodeView(),
            ],
          ),
    );
  }

  Widget _buildDisconnectView() {
    return Center(
      child: CleanCard(
        padding: const EdgeInsets.all(32),
        borderRadius: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: AppColors.statusBusy),
            const SizedBox(height: 24),
            const Text(
              "현재 파트너와 연결되어 있습니다.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _isConnecting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _disconnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusBusy,
                        foregroundColor: Colors.white,
                        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: const Text('연결 끊기', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CleanCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text('나의 초대 코드', style: TextStyle(color: AppColors.textSecondaryDay)),
                  const SizedBox(height: 16),
                  if (_inviteCode != null) ...[
                    Text(
                      _inviteCode!,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _inviteCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('클립보드에 복사되었습니다.')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 20),
                      label: const Text('복사하기'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.statusOnline,
                      ),
                    ),
                  ] else ...[
                     const Text("- - - - - -", style: TextStyle(fontSize: 32, color: Colors.grey)),
                     const SizedBox(height: 16),
                     const Text('초대 코드를 생성하여 파트너에게 공유하세요'),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: _isGenerating
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _generateCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusOnline,
                              foregroundColor: Colors.white,
                              shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: const Text('코드 생성', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterCodeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             CleanCard(
               padding: const EdgeInsets.all(32),
               child: Column(
                 children: [
                   const Text('파트너의 초대 코드를 입력하세요', style: TextStyle(color: AppColors.textSecondaryDay)),
                   const SizedBox(height: 24),
                   TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF5F5F5), // Light gray bg for input
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        hintText: 'A1B2C3',
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 32),
                   SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: _isConnecting
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _connect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.statusOnline,
                                foregroundColor: Colors.white,
                                shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 0,
                              ),
                              child: const Text('연결하기', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                   ),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }
}
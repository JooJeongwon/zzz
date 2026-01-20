import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class ConnectCoupleScreen extends StatefulWidget {
  const ConnectCoupleScreen({super.key});

  @override
  State<ConnectCoupleScreen> createState() => _ConnectCoupleScreenState();
}

class _ConnectCoupleScreenState extends State<ConnectCoupleScreen> with SingleTickerProviderStateMixin {
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
    final invite = await ApiService.createInviteCode();
    setState(() {
      _isGenerating = false;
      _inviteCode = invite?.code;
    });
  }

  Future<void> _connect() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isConnecting = true);
    final success = await ApiService.connectCouple(code);
    setState(() => _isConnecting = false);

    if (success) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결 실패. 코드를 확인해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('파트너 연결'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '내 초대 코드'),
            Tab(text: '코드 입력'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Invite Code Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_inviteCode != null) ...[
                  const Text('나의 초대 코드', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                    _inviteCode!,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('클립보드에 복사되었습니다.')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('복사'),
                  ),
                ] else
                  const Text('초대 코드를 생성하여 파트너에게 공유하세요'),
                const SizedBox(height: 30),
                _isGenerating
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _generateCode,
                        child: const Text('코드 생성'),
                      ),
              ],
            ),
          ),

          // Enter Code Tab
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('파트너에게 받은 코드를 입력하세요'),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '초대 코드',
                    hintText: '예: A1B2C3',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 2),
                ),
                const SizedBox(height: 30),
                _isConnecting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _connect,
                        child: const Text('연결하기'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

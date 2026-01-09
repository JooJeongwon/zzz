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
        const SnackBar(content: Text('Failed to connect. Invalid code or error.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with Partner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Code'),
            Tab(text: 'Enter Code'),
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
                  const Text('Your Invite Code', style: TextStyle(color: Colors.grey)),
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
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ] else
                  const Text('Generate a code to invite your partner'),
                const SizedBox(height: 30),
                _isGenerating
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _generateCode,
                        child: const Text('Generate Code'),
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
                const Text('Enter the code from your partner'),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Invite Code',
                    hintText: 'e.g. A1B2C3',
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
                        child: const Text('Connect'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';
import '../models/partner_status.dart';
import '../models/user_status.dart';
import '../services/api_service.dart';
import '../widgets/status_change_dialog.dart';
import 'login_screen.dart';
import 'connect_couple_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.joo.zzz.app/heartbeat');
  
  PartnerStatus? _partnerStatus;
  bool _isLoading = true;
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
      if (status == null && _partnerStatus == null) {
        // First load failed
      }
      
      if (mounted) {
        setState(() {
          if (status != null) {
              _partnerStatus = status;
              _updateWidget(status);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (e.toString().contains('403')) {
        _timer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please login again.')),
          );
          _logout();
        }
      }
    }
  }

    Future<void> _updateMyStatus(UserStatus status, int? duration) async {

      setState(() => _myStatus = status); // Optimistic update

      final success = await ApiService.updateStatus(status, durationMinutes: duration);

      

      if (!mounted) return;

  

      if (!success) {

         // Revert or show error

         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));

      }

    }

  

    Future<void> _startHeartbeatService() async {

      String message;

      try {

        final userId = await ApiService.getUserId();

        if (userId == null) {

          message = "Error: User ID not found.";

        }

        else {

          final String result = await platform.invokeMethod('startHeartbeat', {'userId': userId});

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

        body: _isLoading 

          ? const Center(child: CircularProgressIndicator()) 

          : _buildBody(),

        floatingActionButton: FloatingActionButton(

          onPressed: _startHeartbeatService,

          tooltip: 'Start Background Service',

          child: const Icon(Icons.favorite),

        ),

      );

    }

  

        Widget _buildBody() {

  

          if (_partnerStatus == null) {

  

            return Center(

  

              child: Column(

  

                mainAxisAlignment: MainAxisAlignment.center,

  

                children: [

  

                  const Text('No partner info available.'),

  

                  const SizedBox(height: 20),

  

                  ElevatedButton(

  

                    onPressed: () {

  

                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectCoupleScreen()));

  

                    },

  

                    child: const Text('Connect with Partner'),

  

                  ),

  

                ],

  

              ),

  

            );

  

          }

  

      

  

          final partner = _partnerStatus!;

  

          final color = partner.status.color;

  

      

  

          return SingleChildScrollView(

  

            padding: const EdgeInsets.all(16),

  

            child: Column(

  

              crossAxisAlignment: CrossAxisAlignment.stretch,

  

              children: [

  

                // My Status Selector

  

                Card(

  

                  elevation: 2,

  

                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

  

                  child: InkWell(

  

                    onTap: () {

  

                      showDialog(

  

                        context: context,

  

                        builder: (context) => StatusChangeDialog(

  

                          currentStatus: _myStatus,

  

                          onStatusSelected: _updateMyStatus,

  

                        ),

  

                      );

  

                    },

  

                    borderRadius: BorderRadius.circular(16),

  

                    child: Padding(

  

                      padding: const EdgeInsets.all(16.0),

  

                      child: Row(

  

                        children: [

  

                          Container(

  

                            padding: const EdgeInsets.all(12),

  

                            decoration: BoxDecoration(

  

                              color: _myStatus.color.withOpacity(0.1),

  

                              shape: BoxShape.circle,

  

                            ),

  

                            child: Icon(_myStatus.icon, color: _myStatus.color, size: 32),

  

                          ),

  

                          const SizedBox(width: 16),

  

                          Column(

  

                            crossAxisAlignment: CrossAxisAlignment.start,

  

                            children: [

  

                              const Text('My Status', style: TextStyle(color: Colors.grey, fontSize: 12)),

  

                              const SizedBox(height: 4),

  

                              Text(

  

                                _myStatus.label,

  

                                style: TextStyle(

  

                                  fontSize: 18, 

  

                                  fontWeight: FontWeight.bold,

  

                                  color: _myStatus.color,

  

                                ),

  

                              ),

  

                            ],

  

                          ),

  

                          const Spacer(),

  

                          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),

  

                        ],

  

                      ),

  

                    ),

  

                  ),

  

                ),

  

                const SizedBox(height: 30),

  

      

  

                // Partner Status Display

  

                Center(

  

                  child: Column(

  

                    children: [

  

                      Text(

  

                        partner.nickname,

  

                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

  

                      ),

  

                      const SizedBox(height: 10),

  

                      Text(

  

                        partner.status.label,

  

                        style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.w500),

  

                      ),

  

                      const SizedBox(height: 20),

  

                      // Character Placeholder

  

                      Container(

  

                        width: 150,

  

                        height: 150,

  

                        decoration: BoxDecoration(

  

                          // ignore: deprecated_member_use

  

                          color: color.withOpacity(0.2),

  

                          shape: BoxShape.circle,

  

                          border: Border.all(color: color, width: 4),

  

                        ),

  

                        child: Icon(

  

                          partner.status.icon,

  

                          size: 80,

  

                          color: color,

  

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

  

                        icon: const Icon(Icons.chat_bubble_outline),

  

                        label: const Text("Chat"),

  

                        style: ElevatedButton.styleFrom(

  

                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),

  

                        ),

  

                      ),

  

      

  

                      const SizedBox(height: 20),

  

                      if (partner.batteryLevel != null)

  

                        Row(

  

                          mainAxisAlignment: MainAxisAlignment.center,

  

                          children: [

  

                            const Icon(Icons.battery_std, size: 20),

  

                            Text('${partner.batteryLevel}%'),

  

                          ],

  

                        ),

  

                      const SizedBox(height: 10),

  

                      if (partner.lastActiveAt != null)

  

                         Text(

  

                          'Last active: ${_formatTime(partner.lastActiveAt!)}',

  

                          style: const TextStyle(color: Colors.grey),

  

                         ),

  

                    ],

  

                  ),

  

                ),

  

                

  

                const SizedBox(height: 40),

  

                Text(_serviceStatusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),

  

              ],

  

            ),

  

          );

  

        }

  

    

  

    String _formatTime(DateTime time) {

      // Using intl package for better formatting

      // Need to import 'package:intl/intl.dart' at top of file

      final now = DateTime.now();

      final diff = now.difference(time);

      if (diff.inMinutes < 1) return '방금 전';

      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';

      if (diff.inHours < 24) return '${diff.inHours}시간 전';

      return DateFormat('M월 d일 a h:mm', 'ko_KR').format(time);

    }

  }

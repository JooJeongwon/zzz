import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class ChatScreen extends StatefulWidget {
  final int partnerId;
  final String partnerName;

  const ChatScreen({Key? key, required this.partnerId, required this.partnerName}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  Timer? _timer;
  int? _myUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final userId = await ApiService.getUserId();
    if (mounted) {
      setState(() {
        _myUserId = userId;
      });
      _fetchMessages();
    }
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages();
    });
  }

  Future<void> _fetchMessages() async {
    if (_myUserId == null) return;
    final messages = await ApiService.getChatHistory(widget.partnerId);
    if (mounted) {
      setState(() {
        _messages = messages; // Already sorted DESC from server
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final content = _controller.text;
    _controller.clear();

    await ApiService.sendMessage(widget.partnerId, content);
    _fetchMessages();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partnerName),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingDots())
                : ListView.builder(
                    reverse: true, // Server sends DESC (newest first)
                    itemCount: _messages.length,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == _myUserId;
                      
                      // Calculate if we need a date separator above this message
                      // Since list is reversed (bottom-up), "above" means visually above,
                      final nextMsg = (index + 1 < _messages.length) ? _messages[index + 1] : null;
                      bool showDate = false;
                      if (nextMsg == null) {
                        showDate = true; // First message ever (at the top)
                      } else if (!_isSameDay(msg.createdAt, nextMsg.createdAt)) {
                        showDate = true; // Date changed
                      }

                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(msg.createdAt),
                          _buildMessageItem(msg, isMe),
                        ],
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR').format(date),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg, bool isMe) {
    if (msg.messageType == 'RECAP') {
      return _buildRecapMessage(msg);
    }
    return _buildNormalMessageRow(msg, isMe);
  }

  Widget _buildRecapMessage(ChatMessage msg) {
    return Column(
      children: [
         Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Row(
            children: [
              const Expanded(child: Divider(color: AppColors.borderDay, thickness: 1.5)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "🌙  부재중 요약  🌙", 
                  style: TextStyle(color: AppColors.statusSleep, fontWeight: FontWeight.bold, fontSize: 12)
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderDay, thickness: 1.5)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
          child: Text(
            msg.content,
            style: const TextStyle(color: AppColors.textSecondaryDay, fontSize: 13, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildNormalMessageRow(ChatMessage msg, bool isMe) {
    final timeStr = DateFormat('a h:mm', 'ko_KR').format(msg.createdAt);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) ...[
            Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: _buildMessageBubble(msg, isMe),
          ),
          if (!isMe) ...[
            const SizedBox(width: 4),
            Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final isAi = msg.isAiGenerated;
    
    // Design: "Paper Cut"
    // No Shadow.
    // Me: Dark Grey BG + White Text.
    // Partner: White BG + Black Text + Light Border.
    // AI: Lavender BG + Dark Purple Text (No Border).
    
    Color bgColor;
    Color textColor;
    BoxBorder? border;

    if (isMe) {
      bgColor = const Color(0xFF353B48); // Dark Grey
      textColor = Colors.white;
      border = null;
    } else if (isAi) {
      bgColor = const Color(0xFFF3E5F5); // Lavender
      textColor = Colors.deepPurple;
      border = null; // No border
    } else {
      // Partner
      bgColor = Colors.white;
      textColor = Colors.black87;
      border = Border.all(color: AppColors.borderDay, width: 1.5);
    }

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
        ),
        border: border,
        // No boxShadow
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                "AI 페르소나", // Localized
                style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7), fontWeight: FontWeight.bold)
              ),
            ),
          Text(
            msg.content, 
            style: TextStyle(fontSize: 16, color: textColor, height: 1.4, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "메시지 보내기...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

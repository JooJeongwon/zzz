import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

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
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true, // Server sends DESC (newest first)
                    itemCount: _messages.length,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == _myUserId;
                      
                      // Calculate if we need a date separator above this message
                      // Since list is reversed (bottom-up), "above" means visually above,
                      // which corresponds to checking the *next* item in the list (which is older).
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
                          _buildMessageRow(msg, isMe),
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

  Widget _buildMessageRow(ChatMessage msg, bool isMe) {
    if (msg.messageType == 'RECAP') {
      return _buildRecapMessage(msg);
    }

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

  Widget _buildRecapMessage(ChatMessage msg) {
    final timeStr = DateFormat('a h:mm', 'ko_KR').format(msg.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.purple.shade100),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.summarize_rounded, color: Colors.purple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "부재중 요약",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.purple.shade800,
                          ),
                        ),
                        Text(
                          "자리를 비운 사이 있었던 일이에요.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1),
                ),
                Text(
                  msg.content,
                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final isAi = msg.isAiGenerated;
    
    // AI Message Styling
    final bgColor = isMe 
        ? Colors.blue[100] 
        : (isAi ? Colors.purple[50] : Colors.grey[200]);
    final borderColor = isAi ? Colors.purple[200] : Colors.transparent;
    final textColor = Colors.black87;

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(2),
          bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(16),
        ),
        border: Border.all(color: borderColor!, width: isAi ? 1.5 : 0),
        boxShadow: isAi ? [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: Colors.purple[700]),
                  const SizedBox(width: 4),
                  Text(
                    "AI Persona", 
                    style: TextStyle(fontSize: 11, color: Colors.purple[700], fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
          Text(
            msg.content, 
            style: TextStyle(fontSize: 15, color: textColor, height: 1.3),
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

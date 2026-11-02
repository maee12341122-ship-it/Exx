import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String userRole; // 'customer', 'admin', 'courier'
  final String targetChat; // 'admin_customer' أو 'admin_courier'

  const ChatScreen({
    Key? key,
    required this.orderId,
    required this.userRole,
    required this.targetChat,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final messages = appState.getMessagesForOrder(widget.orderId, widget.targetChat);

    String chatTitle = widget.targetChat == 'admin_courier'
        ? 'محادثة المشرف مع المندوب (طلب #${widget.orderId})'
        : 'محادثة المشرف مع العميل (طلب #${widget.orderId})';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(chatTitle, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        body: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(child: Text('لا توجد رسائل بعد، ابدأ المحادثة الآن', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  bool isMe = msg.senderRole == widget.userRole;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.amber[800] : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.senderRole == 'admin' ? 'الإدارة' : (msg.senderRole == 'courier' ? 'المندوب' : 'العميل'),
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(msg.message, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFF1E1E1E),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.amber),
                    onPressed: () {
                      if (_msgController.text.trim().isNotEmpty) {
                        appState.sendChatMessage(
                          widget.orderId,
                          widget.userRole,
                          widget.targetChat,
                          _msgController.text,
                        );
                        _msgController.clear();
                      }
                    },
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
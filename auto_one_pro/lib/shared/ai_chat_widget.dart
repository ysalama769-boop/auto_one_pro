import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// AI CHAT BUBBLE — زرار عائم بصورة الأفندي، بيفتح لوحة شات
// بتتكلم مع دالة "ai-chat" على Supabase (اللي هي بترجع لـ
// Claude API بأمان من غير ما يبان المفتاح في الموقع).
// ============================================================
class AiChatBubble extends StatefulWidget {
  final bool isArabic;
  const AiChatBubble({super.key, required this.isArabic});

  @override
  State<AiChatBubble> createState() => _AiChatBubbleState();
}

class _AiChatBubbleState extends State<AiChatBubble> {
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: widget.isArabic ? null : 20,
      left: widget.isArabic ? 20 : null,
      child: isOpen
          ? _ChatPanel(
              isArabic: widget.isArabic,
              onClose: () => setState(() => isOpen = false),
            )
          : GestureDetector(
              onTap: () => setState(() => isOpen = true),
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/chat-bot-avatar.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  _ChatMessage({required this.role, required this.content});
}

class _ChatPanel extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onClose;

  const _ChatPanel({required this.isArabic, required this.onClose});

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final List<_ChatMessage> messages = [];
  final TextEditingController inputCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();
  bool isSending = false;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    messages.add(
      _ChatMessage(
        role: 'assistant',
        content: isArabic
            ? 'أهلًا بيك في أوتو ون! أقدر أساعدك تلاقي سيارة مناسبة، أو أجاوبك على أي سؤال عن المعرض. 🚗'
            : 'Welcome to AUTO ONE! I can help you find the right car, or answer any question about the dealership. 🚗',
      ),
    );
  }

  @override
  void dispose() {
    inputCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollCtrl.hasClients) return;
      scrollCtrl.animateTo(
        scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = inputCtrl.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() {
      messages.add(_ChatMessage(role: 'user', content: text));
      inputCtrl.clear();
      isSending = true;
    });
    _scrollToBottom();

    try {
      // بنبعت آخر 10 رسايل بس كتاريخ، عشان الطلب يفضل خفيف
      final history = messages
          .where((m) => m != messages.last)
          .toList()
          .reversed
          .take(10)
          .toList()
          .reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final response = await Supabase.instance.client.functions.invoke(
        'ai-chat',
        body: {
          'message': text,
          'history': history,
          'isArabic': isArabic,
        },
      );

      final data = response.data;
      final reply = (data is Map && data['reply'] != null)
          ? data['reply'].toString()
          : (isArabic
              ? 'حصلت مشكلة، جرّب تاني'
              : 'Something went wrong, please try again');

      setState(() {
        messages.add(_ChatMessage(role: 'assistant', content: reply));
        isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        messages.add(
          _ChatMessage(
            role: 'assistant',
            content: isArabic
                ? 'تعذّر الاتصال حاليًا، جرّب تاني بعد شوية.'
                : 'Could not connect right now, please try again shortly.',
          ),
        );
        isSending = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 460,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ==================================================
          // HEADER
          // ==================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/chat-bot-avatar.webp',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic ? 'مساعد أوتو ون' : 'AUTO ONE Assistant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ==================================================
          // MESSAGES
          // ==================================================
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length + (isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final msg = messages[index];
                final isUser = msg.role == 'user';
                return Align(
                  alignment: isUser
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    constraints: const BoxConstraints(maxWidth: 250),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.red : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      msg.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ==================================================
          // INPUT
          // ==================================================
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputCtrl,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText:
                          isArabic ? 'اكتب رسالتك...' : 'Type a message...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: isSending ? null : _send,
                  icon: const Icon(Icons.send_rounded, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

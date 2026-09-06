import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/chat/application/chats_controller.dart';
import 'package:vput/features/chat/domain/chat_thread.dart';

/// One conversation: what was said and the field to say the next thing.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.threadId, required this.onBack, super.key});

  static const messageFieldKey = Key('chat_message_field');
  static const sendButtonKey = Key('chat_send');
  static const emptyStateKey = Key('chat_empty');

  static Key messageKey(String id) => Key('chat_message_$id');

  final String threadId;
  final VoidCallback onBack;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    ref.read(chatsProvider.notifier).send(widget.threadId, text);
    _controller.clear();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(chatsProvider);
    final thread = ref.read(chatsProvider.notifier).findById(widget.threadId);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ScreenHeader(
                title: thread?.peerName ?? 'Чат',
                onBack: widget.onBack,
              ),
            ),
            Expanded(
              child: thread == null || thread.messages.isEmpty
                  ? const _EmptyChat()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: thread.messages.length,
                      itemBuilder: (context, index) =>
                          _MessageBubble(message: thread.messages[index]),
                    ),
            ),
            _Composer(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              onSend: _controller.text.trim().isEmpty ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ChatScreen.emptyStateKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Сообщений пока нет. Напишите первым — попутчик получит уведомление.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.33,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    return Padding(
      key: ChatScreen.messageKey(message.id),
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .75,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? AppColors.brandGreen : AppColors.accentWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: mine ? AppColors.accentWhite : AppColors.accentBlack,
                    fontSize: 15,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  RussianDateLabels.time(message.sentAt),
                  style: TextStyle(
                    color: mine
                        ? AppColors.accentWhite.withValues(alpha: .8)
                        : AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.accentWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                key: ChatScreen.messageFieldKey,
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => onSend?.call(),
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: AppColors.accentBlack,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  height: 1.33,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  hintText: 'Сообщение',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: 48,
            child: IconButton.filled(
              key: ChatScreen.sendButtonKey,
              onPressed: onSend,
              padding: EdgeInsets.zero,
              tooltip: 'Отправить',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.accentWhite,
                disabledBackgroundColor: AppColors.divider,
                disabledForegroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_upward_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

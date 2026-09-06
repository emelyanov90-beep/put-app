import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/chat/application/chats_controller.dart';
import 'package:vput/features/chat/domain/chat_thread.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_bottom_bar.dart';

/// «Чаты» — every conversation the user has going.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({
    required this.onOpenThread,
    this.onBack,
    this.onTrips,
    this.onOrders,
    this.onCreate,
    this.onProfile,
    super.key,
  });

  static const emptyStateKey = Key('chats_empty');

  static Key threadKey(String id) => Key('chats_thread_$id');

  final ValueChanged<ChatThread> onOpenThread;

  /// Set when the screen is pushed on top of something rather than opened as
  /// the «Чаты» tab.
  final VoidCallback? onBack;

  /// Tab navigation; without these the bottom bar is not shown.
  final VoidCallback? onTrips;
  final VoidCallback? onOrders;
  final VoidCallback? onCreate;
  final VoidCallback? onProfile;

  bool get _hasTabs =>
      onTrips != null &&
      onOrders != null &&
      onCreate != null &&
      onProfile != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(chatThreadsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _hasTabs
          ? PassengerBottomBar(
              currentItem: PassengerNavigationItem.chats,
              onTrips: onTrips!,
              onOrders: onOrders!,
              onCreate: onCreate!,
              onChats: () {},
              onProfile: onProfile!,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  if (onBack != null)
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                        ),
                      ),
                    ),
                  const Expanded(
                    child: Text(
                      'Чаты',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (onBack != null) const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: threads.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: threads.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _ThreadRow(
                        thread: threads[index],
                        onTap: () => onOpenThread(threads[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = thread.lastMessage;
    final avatar = thread.peerAvatarAsset;
    return Material(
      color: AppColors.accentWhite,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ChatsScreen.threadKey(thread.id),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.divider,
                foregroundImage: avatar == null ? null : AssetImage(avatar),
                child: avatar == null
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.peerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                    if (last != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        last.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (last != null) ...[
                const SizedBox(width: 8),
                Text(
                  RussianDateLabels.time(last.sentAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.38,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ChatsScreen.emptyStateKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.divider,
            ),
            SizedBox(height: 12),
            Text(
              'Чатов пока нет',
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.29,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Чат появится, когда вы напишете попутчику по поездке',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF95969C),
                fontSize: 15,
                height: 1.33,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final RideMatch match;
  const ChatScreen({super.key, required this.match});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final text = TextEditingController(), scroll = ScrollController();
  bool sending = false;
  int lastCount = -1;
  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? quick]) async {
    final value = (quick ?? text.text).trim(),
        student = ref.read(currentStudentProvider);
    if (value.isEmpty || student == null || sending) return;
    setState(() => sending = true);
    try {
      await ref
          .read(repositoryProvider)
          .sendMessage(widget.match.id, student, value);
      if (mounted) text.clear();
    } catch (e) {
      if (mounted) notify(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProvider),
        all = ref.watch(matchesProvider).valueOrNull ?? [];
    final current = all.where((m) => m.id == widget.match.id).toList();
    final m = current.isEmpty ? widget.match : current.first;
    final driver = m.driverId == student?.id,
        cancelled = m.status == MatchStatus.cancelled;
    final person = driver ? m.riderName : m.driverName;
    final messages = ref.watch(messagesProvider(m.id));
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 20, 17),
              child: Row(
                children: [
                  RoundButton(
                    'arrow-left',
                    label: 'Back',
                    onPressed: () => Navigator.pop(context),
                    background: AppColors.background,
                  ),
                  const SizedBox(width: 10),
                  Avatar(
                    name: person,
                    asset: driver ? m.riderAvatar : m.driverAvatar,
                    size: 41,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${driver ? 'Your rider' : 'Your driver'} · ${timeLabel(m.departureAt)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Surface(
                color: AppColors.background,
                radius: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    AppIcon(cancelled ? 'info' : 'shield-check', size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cancelled
                            ? 'This connection was cancelled. Chat is read-only.'
                            : ref.watch(repositoryProvider).isDemo
                            ? 'Local demo chat. No other person is online.'
                            : 'Private conversation. Confirm your pickup here.',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: messages.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, s) =>
                    EmptyState('Couldn’t load chat', friendlyError(e)),
                data: (items) {
                  if (items.length != lastCount) {
                    lastCount = items.length;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && scroll.hasClients) {
                        scroll.animateTo(
                          scroll.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  }
                  if (items.isEmpty) {
                    return const Center(
                      child: EmptyState(
                        'A hello goes a long way.',
                        'Confirm where and when you’ll meet.',
                        icon: 'message-circle',
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final msg = items[i], mine = msg.senderId == student?.id;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * .74,
                          ),
                          margin: const EdgeInsets.only(bottom: 13),
                          padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
                          decoration: BoxDecoration(
                            color: mine ? Colors.black : AppColors.background,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(19),
                              topRight: const Radius.circular(19),
                              bottomLeft: Radius.circular(mine ? 19 : 4),
                              bottomRight: Radius.circular(mine ? 4 : 19),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mine ? Colors.white : Colors.black,
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timeLabel(msg.createdAt),
                                style: TextStyle(
                                  fontSize: 8,
                                  color: mine
                                      ? const Color(0xFFCCCCCC)
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (!cancelled) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                      ),
                      onPressed: sending
                          ? null
                          : () => send('I’m at the pickup point.'),
                      child: const Text(
                        'I’m at the pickup point',
                        style: TextStyle(fontSize: 9),
                      ),
                    ),
                    const SizedBox(width: 9),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                      ),
                      onPressed: sending
                          ? null
                          : () => send(
                              'Running 5 minutes late. Thanks for waiting!',
                            ),
                      child: const Text(
                        'Running 5 min late',
                        style: TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('chat_input'),
                        controller: text,
                        enabled: !sending,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 1000,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => send(),
                        decoration: const InputDecoration(
                          hintText: 'Confirm your pickup…',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        onPressed: sending ? null : () => send(),
                        child: sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const AppIcon(
                                'arrow-up',
                                size: 23,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

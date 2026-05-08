import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:proplinq/features/home/services/chat_service.dart';
import 'package:proplinq/features/auth/services/auth_service.dart';

/// Global, app-wide message notification engine.
///
/// Polls `getUserChats` every few seconds (regardless of which screen is
/// active) and fires a sound + in-app banner + system notification whenever
/// the unread count rises above the previously-seen value.
///
/// Other parts of the app:
///  - listen to [unreadCountNotifier] to update badges
///  - call [setActiveConversationUserId] when the user opens / leaves an
///    individual chat so we don't notify for the conversation they're
///    actively reading
///  - call [acknowledgeAll] from the messages list view (since visiting it
///    counts as having "seen" the unread badge)
class MessageNotificationService {
  static final MessageNotificationService _instance = MessageNotificationService._();
  factory MessageNotificationService() => _instance;
  MessageNotificationService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  bool _initialized = false;
  Timer? _pollTimer;
  String? _activeConversationUserId;
  Set<String> _knownMessageIds = {};
  Set<String> _acknowledgedMessageIds = {};
  bool _firstPoll = true;
  bool _acknowledgePending = false;

  /// Public state — total unread message count from the server.
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// Badge count — drops to 0 when user opens the messages tab, rises again
  /// only when a NEW message (one we haven't already shown them) arrives.
  final ValueNotifier<int> badgeCountNotifier = ValueNotifier<int>(0);

  /// The latest [BuildContext] available for showing the in-app banner.
  /// Updated by the root navigator key in main.dart.
  BuildContext? bannerContext;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(settings: initSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Begin global polling. Safe to call multiple times — only one timer runs.
  void startPolling() {
    _pollTimer?.cancel();
    _firstPoll = true;
    _knownMessageIds = {};
    // Run immediately, then every 4 seconds
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _poll());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _knownMessageIds = {};
    _acknowledgedMessageIds = {};
    _firstPoll = true;
    unreadCountNotifier.value = 0;
    badgeCountNotifier.value = 0;
  }

  /// Tell the service the user is currently inside a 1:1 chat with [userId].
  /// While set, we will NOT play a sound or show a banner for messages from
  /// that user — they're already reading them.
  void setActiveConversationUserId(String? userId) {
    _activeConversationUserId = userId;
  }

  /// User has opened the messages list — treat all currently-known unread
  /// messages as acknowledged (so we don't re-ping for them).
  ///
  /// Also sets [_acknowledgePending] so the next poll re-snapshots the server
  /// state into [_acknowledgedMessageIds]. This closes the race where messages
  /// arrive on the server between our last poll and this ack — without it,
  /// the next poll would see them as "new" and re-raise the badge.
  void acknowledgeAll() {
    _acknowledgedMessageIds = Set<String>.from(_knownMessageIds);
    badgeCountNotifier.value = 0;
    cancelMessageNotification();
    MessageInAppBanner.dismiss();
    _acknowledgePending = true;
    _poll();
  }

  Future<void> _poll() async {
    try {
      final chatData = await _chatService.getUserChats();
      final currentUser = await _authService.getCurrentUser();
      final currentUserId = currentUser?.id.toString();
      if (currentUserId == null) return;

      final Map<String, bool> hasUnreadByPeer = {};
      final Map<String, bool> hasUnseenByPeer = {};
      final Set<String> seenIds = {};
      final List<Map<String, dynamic>> newIncoming = [];

      for (final chat in chatData) {
        final user = chat['user'] as Map<String, dynamic>?;
        final otherPersonId = user?['id']?.toString() ?? '';
        if (otherPersonId.isEmpty) continue;

        final receivedAt = chat['received_at'] as String?;
        final senderId = chat['sender_id']?.toString();
        final messageId = chat['id']?.toString();
        final isFromMe = senderId == currentUserId;
        final isUnread = receivedAt == null && !isFromMe;

        if (messageId != null) seenIds.add(messageId);

        hasUnreadByPeer[otherPersonId] = (hasUnreadByPeer[otherPersonId] ?? false) || isUnread;

        // "Unseen" = unread AND not yet acknowledged (badge-driving)
        final isUnseen = isUnread && messageId != null && !_acknowledgedMessageIds.contains(messageId);
        hasUnseenByPeer[otherPersonId] = (hasUnseenByPeer[otherPersonId] ?? false) || isUnseen;

        // Brand-new incoming message we've never polled before
        if (isUnread && messageId != null && !_knownMessageIds.contains(messageId) && !_firstPoll) {
          newIncoming.add({
            'peerId': otherPersonId,
            'messageId': messageId,
          });
        }
      }

      _knownMessageIds = seenIds;
      // Drop acknowledged IDs that no longer exist (e.g. server purged old messages)
      _acknowledgedMessageIds = _acknowledgedMessageIds.intersection(seenIds);

      // Consume a pending acknowledgement: the user just opened the messages
      // tab / a chat, so absorb every message the server currently knows
      // about into the acknowledged set. This prevents a flicker where a
      // message that landed on the server between polls would otherwise be
      // treated as "new" on the next poll and re-raise the badge.
      final wasAcknowledgePending = _acknowledgePending;
      if (_acknowledgePending) {
        _acknowledgedMessageIds = Set<String>.from(seenIds);
        _acknowledgePending = false;
        // Recompute hasUnseenByPeer against the freshly-acknowledged set so
        // the badge stays at 0 instead of bouncing.
        hasUnseenByPeer.clear();
      }

      final unreadCount = hasUnreadByPeer.values.where((v) => v).length;
      final badgeCount = hasUnseenByPeer.values.where((v) => v).length;
      unreadCountNotifier.value = unreadCount;
      badgeCountNotifier.value = badgeCount;

      if (kDebugMode) {
        debugPrint('🔔 [MsgService] poll: total=${chatData.length} unread=$unreadCount newIncoming=${newIncoming.length} active=$_activeConversationUserId');
      }

      // Fire notifications for each new incoming message (skip ones in the
      // active conversation since the user is already reading them, and skip
      // the entire batch if this poll was triggered by acknowledgeAll —
      // otherwise opening the messages tab could itself ping for a message
      // that landed during the race window).
      if (!_firstPoll && !wasAcknowledgePending) {
        final notifiable = newIncoming
            .where((m) => m['peerId'] != _activeConversationUserId)
            .toList();
        if (notifiable.isNotEmpty) {
          await _playSound();
          await _showSystemNotification(notifiable.length);
          if (bannerContext != null) {
            try {
              MessageInAppBanner.show(bannerContext!, notifiable.length);
            } catch (e) {
              if (kDebugMode) debugPrint('🔔 [MsgService] banner error: $e');
            }
          }
        }
      }

      _firstPoll = false;
    } catch (e) {
      if (kDebugMode) debugPrint('🔔 [MsgService] poll error: $e');
    }
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/message_notification.wav'));
    } catch (_) {}
  }

  Future<void> _showSystemNotification(int count) async {
    const androidDetails = AndroidNotificationDetails(
      'proplinq_messages',
      'Messages',
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(presentSound: false);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final body = count == 1 ? 'You have 1 new message' : 'You have $count new messages';
    await _localNotifications.show(id: 1001, title: 'Proplinq', body: body, notificationDetails: details);
  }

  Future<void> cancelMessageNotification() async {
    await _localNotifications.cancel(id: 1001);
  }

  /// Backwards-compat alias used by older callsites.
  Future<void> notifyNewMessages(int newCount) async {
    await _playSound();
    await _showSystemNotification(newCount);
  }

  void dispose() {
    _pollTimer?.cancel();
    _audioPlayer.dispose();
  }
}

/// Overlay-based in-app toast banner for new messages.
class MessageInAppBanner {
  static OverlayEntry? _entry;

  static void show(BuildContext context, int count) {
    _entry?.remove();
    _entry = null;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final body = count == 1 ? 'You have 1 new message' : 'You have $count new messages';

    final entry = OverlayEntry(builder: (_) => _MessageBannerWidget(message: body, onDismiss: dismiss));
    _entry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 4), () {
      if (_entry == entry) dismiss();
    });
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _MessageBannerWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  const _MessageBannerWidget({required this.message, required this.onDismiss});

  @override
  State<_MessageBannerWidget> createState() => _MessageBannerWidgetState();
}

class _MessageBannerWidgetState extends State<_MessageBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B4A),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF426DC2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.message, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'New Message',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: const TextStyle(color: Color(0xFFB0C4DE), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.close, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

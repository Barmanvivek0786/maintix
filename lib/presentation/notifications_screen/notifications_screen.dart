import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final appState = context.read<AppState>();
    final userId = appState.currentUserId;
    if (userId == null) {
      // Logged out: never show anything from a previous account.
      if (mounted) {
        setState(() {
          _notifications = [];
          _loading = false;
        });
      }
      return;
    }
    final list = await NotificationService.instance.fetchNotifications(userId);

    // If the account changed (logout / login as someone else) while this
    // request was in flight, drop the result so old-account data never shows.
    if (!mounted || appState.currentUserId != userId) return;

    await NotificationService.instance.markAllRead(userId);
    if (!mounted || appState.currentUserId != userId) return;

    // Clear the red badge dot in AppState
    appState.clearUnreadNotificationCount();
    setState(() {
      // Extra safety: only ever keep rows that belong to the current user.
      _notifications = list.where((n) => n.userId == userId).toList();
      _loading = false;
    });
  }

  Future<void> _deleteNotification(String id) async {
    await NotificationService.instance.deleteNotification(id);
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_today_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'reward':
        return Icons.monetization_on_rounded;
      case 'broadcast':
        return Icons.campaign_rounded;
      case 'welcome':
        return Icons.celebration_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'booking':
        return const Color(0xFF0D9488);
      case 'payment':
        return const Color(0xFF10B981);
      case 'reward':
        return const Color(0xFFF59E0B);
      case 'broadcast':
        return const Color(0xFF6366F1);
      case 'welcome':
        return const Color(0xFFEC4899);
      default:
        return AppTheme.primaryNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                final appState = context.read<AppState>();
                final userId = appState.currentUserId;
                if (userId != null) {
                  for (final n in _notifications) {
                    await NotificationService.instance.deleteNotification(n.id);
                  }
                  setState(() => _notifications.clear());
                }
              },
              child: Text(
                'Clear All',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  return _buildNotificationCard(n);
                },
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 36,
              color: AppTheme.primaryNavy.withAlpha(102),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your alerts and updates will appear here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n) {
    final color = _colorForType(n.type);
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(n.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.isRead ? AppTheme.divider : color.withAlpha(77),
            width: n.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(31),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconForType(n.type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Inline copy button for coupon-type notifications
                  if (n.type == 'coupon' || _extractCouponCode(n.body) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _buildCopyCodeButton(n.body),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(n.createdAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textSecondary.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extracts a coupon code (all-caps word 4-10 chars) from notification body
  String? _extractCouponCode(String body) {
    final match = RegExp(r'\b([A-Z0-9]{4,10})\b').firstMatch(body);
    return match?.group(1);
  }

  Widget _buildCopyCodeButton(String body) {
    final code = _extractCouponCode(body);
    if (code == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon copied! Use "$code" at checkout.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.primaryNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.tealAccent.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.tealAccent.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_rounded, size: 12, color: AppTheme.tealAccent),
            const SizedBox(width: 4),
            Text(
              'Copy: $code',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.tealAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

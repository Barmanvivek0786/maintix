import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _checkingAdmin = true;
  bool _isAdmin = false;
  bool _waitingForSession = true;
  StreamSubscription<AuthState>? _authSubscription;

  // Broadcast
  final _broadcastTitleCtrl = TextEditingController();
  final _broadcastBodyCtrl = TextEditingController();
  bool _broadcasting = false;

  // Data
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _loadingBookings = false;
  bool _loadingUsers = false;
  bool _loadingReviews = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _waitForSessionThenCheck();
  }

  Future<void> _waitForSessionThenCheck() async {
    final client = Supabase.instance.client;

    if (client.auth.currentUser != null) {
      if (mounted) setState(() => _waitingForSession = false);
      await _checkAdminAccess();
      return;
    }

    final completer = Completer<void>();

    _authSubscription = client.auth.onAuthStateChange.listen((data) {
      if (!completer.isCompleted) {
        final event = data.event;
        if (event == AuthChangeEvent.initialSession ||
            event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.signedOut) {
          completer.complete();
        }
      }
    });

    await Future.any([
      completer.future,
      Future.delayed(const Duration(seconds: 5)),
    ]);

    _authSubscription?.cancel();
    _authSubscription = null;

    if (mounted) {
      setState(() => _waitingForSession = false);
      await _checkAdminAccess();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tabController.dispose();
    _broadcastTitleCtrl.dispose();
    _broadcastBodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        setState(() {
          _checkingAdmin = false;
          _isAdmin = false;
        });
        return;
      }
      final profile = await _client
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .maybeSingle();
      final isAdmin = profile?['is_admin'] as bool? ?? false;
      setState(() {
        _checkingAdmin = false;
        _isAdmin = isAdmin;
      });
      if (isAdmin) {
        _loadAllData();
      }
    } catch (e) {
      setState(() {
        _checkingAdmin = false;
        _isAdmin = false;
      });
    }
  }

  Future<void> _loadAllData() async {
    _loadBookings();
    _loadUsers();
    _loadReviews();
  }

  Future<void> _loadBookings() async {
    setState(() => _loadingBookings = true);
    try {
      final data = await _client
          .from('bookings')
          .select('*, profiles(full_name, email, phone_number)')
          .order('created_at', ascending: false);
      setState(() => _bookings = List<Map<String, dynamic>>.from(data as List));
    } catch (e) {
      debugPrint('loadBookings error: $e');
    }
    setState(() => _loadingBookings = false);
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final data = await _client
          .from('profiles')
          .select('*, user_coins(balance)')
          .order('email', ascending: true);
      setState(() => _users = List<Map<String, dynamic>>.from(data as List));
    } catch (e) {
      debugPrint('loadUsers error: $e');
    }
    setState(() => _loadingUsers = false);
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final data = await _client
          .from('reviews')
          .select('*, profiles(full_name, email)')
          .order('created_at', ascending: false);
      setState(() => _reviews = List<Map<String, dynamic>>.from(data as List));
    } catch (e) {
      debugPrint('loadReviews error: $e');
    }
    setState(() => _loadingReviews = false);
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _client
          .from('bookings')
          .update({'status': status})
          .eq('id', bookingId);
      _loadBookings();
      _showSnack('Booking status updated to $status', success: true);
    } catch (e) {
      _showSnack('Failed to update status');
    }
  }

  Future<void> _deleteBooking(String bookingId) async {
    try {
      await _client.from('bookings').delete().eq('id', bookingId);
      setState(() => _bookings.removeWhere((b) => b['id'] == bookingId));
      _showSnack('Booking deleted', success: true);
    } catch (e) {
      _showSnack('Failed to delete booking');
    }
  }

  Future<void> _updateUserCoins(String userId, int newBalance) async {
    try {
      await _client
          .from('user_coins')
          .update({'balance': newBalance})
          .eq('user_id', userId);
      _loadUsers();
      _showSnack('Coin balance updated', success: true);
    } catch (e) {
      _showSnack('Failed to update coins');
    }
  }

  Future<void> _approveReview(String reviewId) async {
    try {
      await _client
          .from('reviews')
          .update({'is_approved': true})
          .eq('id', reviewId);
      setState(() {
        final idx = _reviews.indexWhere((r) => r['id'] == reviewId);
        if (idx != -1) {
          _reviews[idx] = Map<String, dynamic>.from(_reviews[idx])
            ..['is_approved'] = true;
        }
      });
      _showSnack('Review approved and published! ✅', success: true);
    } catch (e) {
      _showSnack('Failed to approve review');
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await _client.from('reviews').delete().eq('id', reviewId);
      setState(() => _reviews.removeWhere((r) => r['id'] == reviewId));
      _showSnack('Review deleted', success: true);
    } catch (e) {
      _showSnack('Failed to delete review');
    }
  }

  Future<void> _sendBroadcast() async {
    final title = _broadcastTitleCtrl.text.trim();
    final body = _broadcastBodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      _showSnack('Please fill in both title and message');
      return;
    }
    setState(() => _broadcasting = true);
    final user = _client.auth.currentUser;
    final success = await NotificationService.instance.broadcastToAllUsers(
      title: title,
      body: body,
      sentBy: user?.id ?? '',
    );
    setState(() => _broadcasting = false);
    if (success) {
      _broadcastTitleCtrl.clear();
      _broadcastBodyCtrl.clear();
      _showSnack('Broadcast sent to all users! 🎉', success: true);
    } else {
      _showSnack('Failed to send broadcast');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showEditCoinsDialog(Map<String, dynamic> user) {
    final coins = (user['user_coins'] as List?)?.isNotEmpty == true
        ? (user['user_coins'][0]['balance'] as int? ?? 0)
        : 0;
    final ctrl = TextEditingController(text: coins.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Coins',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['full_name'] as String? ?? user['email'] as String? ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.inputTextColor(context),
              ),
              decoration: InputDecoration(
                labelText: 'New Coin Balance',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
                filled: true,
                fillColor: AppTheme.inputFillColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppTheme.tealAccent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val >= 0) {
                Navigator.pop(ctx);
                _updateUserCoins(user['id'] as String, val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Update',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_waitingForSession || _checkingAdmin) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.tealAccent),
              const SizedBox(height: 16),
              Text(
                'Loading Admin Panel...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryNavy,
          foregroundColor: Colors.white,
          title: Text(
            'Admin Panel',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have admin privileges.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '🛡️ Admin Panel',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.tealAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.campaign_rounded, size: 18),
              text: 'Broadcast',
            ),
            Tab(
              icon: Icon(Icons.calendar_today_rounded, size: 18),
              text: 'Bookings',
            ),
            Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.star_rounded, size: 18), text: 'Reviews'),
            Tab(
              icon: Icon(Icons.rate_review_rounded, size: 18),
              text: 'Manage Reviews',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBroadcastTab(),
          _buildBookingsTab(),
          _buildUsersTab(),
          _buildReviewsTab(),
          _buildManageReviewsTab(),
        ],
      ),
    );
  }

  // ─── Broadcast Tab ────────────────────────────────────────────────────────

  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryNavy,
                  AppTheme.primaryNavy.withAlpha(217),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Broadcaster Tool',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Send push notifications to all registered users',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _broadcastTitleCtrl,
            label: 'Notification Title',
            hint: 'e.g. Special Offer! 🎁',
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _broadcastBodyCtrl,
            label: 'Message Body',
            hint: 'e.g. Get ₹100 off on your next booking!',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _broadcasting ? null : _sendBroadcast,
              icon: _broadcasting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _broadcasting ? 'Sending...' : 'Send to All Users',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppTheme.inputTextColor(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppTheme.textSecondary.withAlpha(128),
        ),
        filled: true,
        fillColor: AppTheme.inputFillColor(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.tealAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  // ─── Bookings Tab ─────────────────────────────────────────────────────────

  Widget _buildBookingsTab() {
    if (_loadingBookings) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bookings.isEmpty) {
      return _buildEmptyState(
        'No bookings found',
        Icons.calendar_today_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final b = _bookings[index];
          final profile = b['profiles'] as Map<String, dynamic>?;
          final status = b['status'] as String? ?? 'Pending';
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardShadow,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b['service_name'] as String? ?? 'Service',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),
                const SizedBox(height: 6),
                _infoRow(
                  Icons.person_rounded,
                  profile?['full_name'] as String? ?? 'Unknown',
                ),
                _infoRow(
                  Icons.phone_rounded,
                  profile?['phone_number'] as String? ?? '-',
                ),
                _infoRow(
                  Icons.location_on_rounded,
                  b['address'] as String? ?? '-',
                ),
                _infoRow(
                  Icons.calendar_today_rounded,
                  '${b['booking_date'] ?? ''} ${b['booking_time'] ?? ''}',
                ),
                _infoRow(Icons.currency_rupee_rounded, '₹${b['price'] ?? 0}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _actionBtn(
                      'Confirm',
                      Icons.check_circle_rounded,
                      const Color(0xFF10B981),
                      () =>
                          _updateBookingStatus(b['id'] as String, 'CONFIRMED'),
                    ),
                    const SizedBox(width: 8),
                    _actionBtn(
                      'Cancel',
                      Icons.cancel_rounded,
                      AppTheme.error,
                      () =>
                          _updateBookingStatus(b['id'] as String, 'CANCELLED'),
                    ),
                    const SizedBox(width: 8),
                    _actionBtn(
                      'Delete',
                      Icons.delete_rounded,
                      Colors.grey,
                      () => _deleteBooking(b['id'] as String),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Users Tab ────────────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_users.isEmpty) {
      return _buildEmptyState('No users found', Icons.people_rounded);
    }
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final u = _users[index];
          final coins = (u['user_coins'] as List?)?.isNotEmpty == true
              ? (u['user_coins'][0]['balance'] as int? ?? 0)
              : 0;
          final isAdmin = u['is_admin'] as bool? ?? false;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardShadow,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (u['full_name'] as String? ?? 'U').isNotEmpty
                          ? (u['full_name'] as String)[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
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
                              u['full_name'] as String? ?? 'Unknown',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryNavy,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Admin',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        u['email'] as String? ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        u['phone_number'] as String? ?? 'No phone',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showEditCoinsDialog(u),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(31),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withAlpha(77),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFF59E0B),
                          size: 16,
                        ),
                        Text(
                          '$coins',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Reviews Tab (read-only view of all reviews) ──────────────────────────

  Widget _buildReviewsTab() {
    if (_loadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reviews.isEmpty) {
      return _buildEmptyState('No reviews found', Icons.star_rounded);
    }
    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final r = _reviews[index];
          final profile = r['profiles'] as Map<String, dynamic>?;
          final rating = (r['rating'] as num?)?.toDouble() ?? 5.0;
          final isApproved = r['is_approved'] as bool? ?? false;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(
                  color: isApproved ? AppTheme.success : AppTheme.warning,
                  width: 3,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardShadow,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile?['full_name'] as String? ?? 'Unknown',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isApproved
                            ? AppTheme.success.withAlpha(26)
                            : AppTheme.warning.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isApproved ? '✅ Approved' : '⏳ Pending',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isApproved
                              ? AppTheme.success
                              : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      profile?['email'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r['review_text'] as String? ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!isApproved) ...[
                      _actionBtn(
                        'Approve',
                        Icons.check_circle_rounded,
                        AppTheme.success,
                        () => _approveReview(r['id'] as String),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _actionBtn(
                      'Delete',
                      Icons.delete_rounded,
                      AppTheme.error,
                      () => _deleteReview(r['id'] as String),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Manage Reviews Tab (pending reviews only) ────────────────────────────

  Widget _buildManageReviewsTab() {
    if (_loadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingReviews = _reviews
        .where((r) => !(r['is_approved'] as bool? ?? false))
        .toList();

    if (pendingReviews.isEmpty) {
      return _buildEmptyState(
        'No pending reviews\nAll reviews are approved!',
        Icons.rate_review_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warning.withAlpha(26),
                  AppTheme.warning.withAlpha(13),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warning.withAlpha(77)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pending_actions_rounded,
                  color: AppTheme.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pendingReviews.length} review${pendingReviews.length != 1 ? 's' : ''} awaiting approval',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pendingReviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = pendingReviews[index];
                final profile = r['profiles'] as Map<String, dynamic>?;
                final rating = (r['rating'] as num?)?.toDouble() ?? 5.0;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(color: AppTheme.warning, width: 3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cardShadow,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.tealAccent.withAlpha(26),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (profile?['full_name'] as String? ?? 'U')
                                        .isNotEmpty
                                    ? (profile!['full_name'] as String)[0]
                                          .toUpperCase()
                                    : 'U',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.tealAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?['full_name'] as String? ?? 'Unknown',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  profile?['email'] as String? ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < rating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        r['review_text'] as String? ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r['service_name'] as String? ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _approveReview(r['id'] as String),
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                              ),
                              label: Text(
                                'Approve',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _deleteReview(r['id'] as String),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                              ),
                              label: Text(
                                'Delete',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.error,
                                side: BorderSide(
                                  color: AppTheme.error.withAlpha(102),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppTheme.textSecondary.withAlpha(102)),
          const SizedBox(height: 12),
          Text(
            msg,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        color = const Color(0xFF10B981);
        break;
      case 'CANCELLED':
        color = AppTheme.error;
        break;
      default:
        color = const Color(0xFFF59E0B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        status,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

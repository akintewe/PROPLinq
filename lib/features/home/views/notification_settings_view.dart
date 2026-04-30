import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/onesignal_service.dart';
import '../../../core/constants/app_colors.dart';

class NotificationSettingsView extends StatefulWidget {
  final bool isAgent;

  const NotificationSettingsView({super.key, this.isAgent = false});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  final OneSignalService _oneSignalService = OneSignalService();

  bool _isLoading = true;
  bool _isSaving = false;

  // ── Shared (both roles) ──────────────────────────────────────────
  bool _notifMessages = true;
  bool _notifAccountActivity = true;

  // ── Homeseeker only ─────────────────────────────────────────────
  bool _notifNewProperties = true;
  bool _notifPriceDrops = true;
  bool _notifBookingUpdates = true;
  bool _notifPromotions = false;

  // ── Agent only ──────────────────────────────────────────────────
  bool _notifNewBookings = true;
  bool _notifBookingCancellations = true;
  bool _notifNewMessages = true;
  bool _notifPropertyViews = false;
  bool _notifKycUpdates = true;
  bool _notifPayments = true;

  static const String _prefsKey = 'notification_settings';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifMessages = prefs.getBool('notif_messages') ?? true;
      _notifAccountActivity = prefs.getBool('notif_account_activity') ?? true;

      _notifNewProperties = prefs.getBool('notif_new_properties') ?? true;
      _notifPriceDrops = prefs.getBool('notif_price_drops') ?? true;
      _notifBookingUpdates = prefs.getBool('notif_booking_updates') ?? true;
      _notifPromotions = prefs.getBool('notif_promotions') ?? false;

      _notifNewBookings = prefs.getBool('notif_new_bookings') ?? true;
      _notifBookingCancellations =
          prefs.getBool('notif_booking_cancellations') ?? true;
      _notifNewMessages = prefs.getBool('notif_new_messages') ?? true;
      _notifPropertyViews = prefs.getBool('notif_property_views') ?? false;
      _notifKycUpdates = prefs.getBool('notif_kyc_updates') ?? true;
      _notifPayments = prefs.getBool('notif_payments') ?? true;

      _isLoading = false;
    });
  }

  Future<void> _saveAndSync() async {
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();

    // Persist locally
    await prefs.setBool('notif_messages', _notifMessages);
    await prefs.setBool('notif_account_activity', _notifAccountActivity);
    await prefs.setBool('notif_new_properties', _notifNewProperties);
    await prefs.setBool('notif_price_drops', _notifPriceDrops);
    await prefs.setBool('notif_booking_updates', _notifBookingUpdates);
    await prefs.setBool('notif_promotions', _notifPromotions);
    await prefs.setBool('notif_new_bookings', _notifNewBookings);
    await prefs.setBool('notif_booking_cancellations',
        _notifBookingCancellations);
    await prefs.setBool('notif_new_messages', _notifNewMessages);
    await prefs.setBool('notif_property_views', _notifPropertyViews);
    await prefs.setBool('notif_kyc_updates', _notifKycUpdates);
    await prefs.setBool('notif_payments', _notifPayments);

    // Sync to OneSignal as tags (backend uses these for targeted sends)
    final tags = <String, String>{
      'notif_messages': _notifMessages ? '1' : '0',
      'notif_account_activity': _notifAccountActivity ? '1' : '0',
    };

    if (widget.isAgent) {
      tags['notif_new_bookings'] = _notifNewBookings ? '1' : '0';
      tags['notif_booking_cancellations'] =
          _notifBookingCancellations ? '1' : '0';
      tags['notif_new_messages'] = _notifNewMessages ? '1' : '0';
      tags['notif_property_views'] = _notifPropertyViews ? '1' : '0';
      tags['notif_kyc_updates'] = _notifKycUpdates ? '1' : '0';
      tags['notif_payments'] = _notifPayments ? '1' : '0';
    } else {
      tags['notif_new_properties'] = _notifNewProperties ? '1' : '0';
      tags['notif_price_drops'] = _notifPriceDrops ? '1' : '0';
      tags['notif_booking_updates'] = _notifBookingUpdates ? '1' : '0';
      tags['notif_promotions'] = _notifPromotions ? '1' : '0';
    }

    await _oneSignalService.setUserTags(tags);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification preferences saved'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF426DC2)))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIntroCard(),
                        const SizedBox(height: 24),

                        // ── General ──────────────────────────────
                        _buildSectionHeader('General'),
                        const SizedBox(height: 12),
                        _buildToggleTile(
                          icon: Icons.chat_bubble_outline,
                          title: 'Messages',
                          subtitle: 'New messages from agents or users',
                          value: _notifMessages,
                          onChanged: (v) => setState(() => _notifMessages = v),
                        ),
                        _buildToggleTile(
                          icon: Icons.manage_accounts_outlined,
                          title: 'Account activity',
                          subtitle: 'Login alerts, password changes',
                          value: _notifAccountActivity,
                          onChanged: (v) =>
                              setState(() => _notifAccountActivity = v),
                        ),

                        const SizedBox(height: 24),

                        // ── Role-specific ─────────────────────────
                        if (widget.isAgent) ...[
                          _buildSectionHeader('Bookings & Listings'),
                          const SizedBox(height: 12),
                          _buildToggleTile(
                            icon: Icons.calendar_today_outlined,
                            title: 'New bookings',
                            subtitle: 'When a guest books your property',
                            value: _notifNewBookings,
                            onChanged: (v) =>
                                setState(() => _notifNewBookings = v),
                          ),
                          _buildToggleTile(
                            icon: Icons.cancel_outlined,
                            title: 'Booking cancellations',
                            subtitle: 'When a guest cancels a booking',
                            value: _notifBookingCancellations,
                            onChanged: (v) =>
                                setState(() => _notifBookingCancellations = v),
                          ),
                          _buildToggleTile(
                            icon: Icons.visibility_outlined,
                            title: 'Property views',
                            subtitle: 'When someone views your listing',
                            value: _notifPropertyViews,
                            onChanged: (v) =>
                                setState(() => _notifPropertyViews = v),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Finance & Verification'),
                          const SizedBox(height: 12),
                          _buildToggleTile(
                            icon: Icons.payments_outlined,
                            title: 'Payments',
                            subtitle: 'Deposits, payouts, and payment updates',
                            value: _notifPayments,
                            onChanged: (v) =>
                                setState(() => _notifPayments = v),
                          ),
                          _buildToggleTile(
                            icon: Icons.verified_outlined,
                            title: 'KYC updates',
                            subtitle: 'Verification status changes',
                            value: _notifKycUpdates,
                            onChanged: (v) =>
                                setState(() => _notifKycUpdates = v),
                          ),
                          _buildToggleTile(
                            icon: Icons.message_outlined,
                            title: 'New messages',
                            subtitle: 'Messages from potential guests',
                            value: _notifNewMessages,
                            onChanged: (v) =>
                                setState(() => _notifNewMessages = v),
                          ),
                        ] else ...[
                          _buildSectionHeader('Properties & Bookings'),
                          const SizedBox(height: 12),
                          _buildToggleTile(
                            icon: Icons.home_outlined,
                            title: 'New properties',
                            subtitle:
                                'Properties that match your saved searches',
                            value: _notifNewProperties,
                            onChanged: (v) =>
                                setState(() => _notifNewProperties = v),
                          ),
                          _buildToggleTile(
                            icon: Icons.trending_down_outlined,
                            title: 'Price drops',
                            subtitle: 'When a saved property drops in price',
                            value: _notifPriceDrops,
                            onChanged: (v) =>
                                setState(() => _notifPriceDrops = v),
                          ),
                          _buildToggleTile(
                            icon: Icons.hotel_outlined,
                            title: 'Booking updates',
                            subtitle: 'Check-in reminders and booking status',
                            value: _notifBookingUpdates,
                            onChanged: (v) =>
                                setState(() => _notifBookingUpdates = v),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Marketing'),
                          const SizedBox(height: 12),
                          _buildToggleTile(
                            icon: Icons.local_offer_outlined,
                            title: 'Promotions & offers',
                            subtitle: 'Deals, discounts, and featured listings',
                            value: _notifPromotions,
                            onChanged: (v) =>
                                setState(() => _notifPromotions = v),
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Save button pinned at bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF426DC2),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF426DC2).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save preferences',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECF0F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined,
              color: Color(0xFF426DC2), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Choose which notifications you want to receive. Changes take effect immediately.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF426DC2),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFECF0F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF426DC2)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF426DC2),
          ),
        ],
      ),
    );
  }
}

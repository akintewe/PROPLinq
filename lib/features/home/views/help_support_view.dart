import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/storage_service.dart';

class HelpSupportView extends StatefulWidget {
  const HelpSupportView({super.key});

  @override
  State<HelpSupportView> createState() => _HelpSupportViewState();
}

class _HelpSupportViewState extends State<HelpSupportView> with SingleTickerProviderStateMixin {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _submitted = false;

  late final TabController _tabController;
  List<Map<String, dynamic>> _tickets = [];
  bool _loadingTickets = false;
  String? _ticketsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _tickets.isEmpty && !_loadingTickets) {
        _loadTickets();
      }
    });
    // Pre-load tickets so they're ready when the user switches tabs
    _loadTickets();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() { _loadingTickets = true; _ticketsError = null; });
    try {
      final token = await StorageService().getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.supportTickets}'),
        headers: ApiConstants.getAuthHeaders(token ?? ''),
      ).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      debugPrint('🎫 [Tickets] Status: ${response.statusCode}');
      debugPrint('🎫 [Tickets] Body: ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body);
        // Backend returns { data: [...] } or { data: { data: [...] } }
        final outer = body['data'];
        final List<dynamic> list;
        if (outer is List) {
          list = outer;
        } else if (outer is Map && outer['data'] is List) {
          list = outer['data'] as List;
        } else {
          list = [];
        }
        setState(() {
          _tickets = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loadingTickets = false;
        });
      } else {
        setState(() { _ticketsError = 'Failed to load tickets'; _loadingTickets = false; });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('🎫 [Tickets] Error: $e');
      setState(() { _ticketsError = 'Failed to load tickets'; _loadingTickets = false; });
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final token = await StorageService().getToken();
      final userData = await StorageService().getUserData();
      final userId = userData?['id']?.toString();
      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.supportTickets}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'subject': _subjectCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          if (userId != null) 'user_id': userId,
        }),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() { _submitted = true; _isSubmitting = false; _tickets = []; });
        _subjectCtrl.clear();
        _descCtrl.clear();
      } else {
        setState(() => _isSubmitting = false);
        final body = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message']?.toString() ?? 'Failed to submit ticket'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit ticket. Please try again.'), backgroundColor: Colors.red),
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
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8, right: 8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEFF0F2), width: 1.14),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, color: Color(0xFF426DC2), size: 20),
              ),
            ),
          ),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF426DC2),
          unselectedLabelColor: const Color(0xFF868686),
          indicatorColor: const Color(0xFF426DC2),
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'New Ticket'),
            Tab(text: 'My Tickets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewTicketTab(),
          _buildMyTicketsTab(),
        ],
      ),
    );
  }

  Widget _buildNewTicketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF426DC2), Color(0xFF63ADDC)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.headset_mic_outlined, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'How can we help?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Submit a ticket and our team will get back to you as soon as possible.',
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // FAQ section
          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
          const SizedBox(height: 12),
          _buildFaq('How do I list a property?', 'Complete your KYC verification, then tap "List a Property" from your agent profile.'),
          _buildFaq('How long does KYC verification take?', 'KYC review typically takes 1–3 business days. You\'ll be notified once it\'s complete.'),
          _buildFaq('How do I cancel a booking?', 'Go to My Bookings, find the booking, and tap "Cancel Booking". Note our cancellation policy may apply.'),
          _buildFaq('How do I fund my wallet?', 'Go to Settings → My Wallet → Fund Wallet and follow the payment steps.'),
          _buildFaq('How do I reset my password?', 'On the login screen, tap "Forgot password" and follow the instructions sent to your email.'),

          const SizedBox(height: 32),
          Divider(height: 1, color: Colors.grey[100]),
          const SizedBox(height: 32),

          if (_submitted)
            _buildSuccessBanner()
          else ...[
            const Text('Submit a Support Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 4),
            const Text(
              'Describe your issue and we\'ll respond within 24 hours.',
              style: TextStyle(fontSize: 13, color: Color(0xFF868686)),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subjectCtrl,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      hintText: 'e.g. Payment not reflecting',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF426DC2), width: 2),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Subject is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your issue in detail...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF426DC2), width: 2),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF426DC2), Color(0xFF63ADDC)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        onPressed: _isSubmitting ? null : _submitTicket,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Submit Ticket',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab() {
    if (_loadingTickets) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF426DC2)));
    }

    if (_ticketsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            Text(_ticketsError!, style: const TextStyle(fontSize: 14, color: Color(0xFF868686))),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadTickets,
              child: const Text('Retry', style: TextStyle(color: Color(0xFF426DC2))),
            ),
          ],
        ),
      );
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 56, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            const Text('No tickets yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
            const SizedBox(height: 6),
            const Text('Submit a ticket from the New Ticket tab', style: TextStyle(fontSize: 13, color: Color(0xFF868686))),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _loadTickets,
              child: const Text('Refresh', style: TextStyle(color: Color(0xFF426DC2))),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF426DC2),
      onRefresh: _loadTickets,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildTicketCard(_tickets[index]),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final id = ticket['uuid']?.toString() ?? ticket['id']?.toString() ?? '';
    final subject = ticket['subject']?.toString() ?? 'No subject';
    final status = ticket['status']?.toString() ?? 'open';
    final createdAt = ticket['created_at']?.toString() ?? '';

    final statusColor = switch (status.toLowerCase()) {
      'open' => const Color(0xFF426DC2),
      'closed' => const Color(0xFF868686),
      'resolved' => const Color(0xFF008D5A),
      _ => const Color(0xFFF09800),
    };
    final statusBg = statusColor.withValues(alpha: 0.1);

    String dateLabel = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateLabel = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TicketDetailView(ticketId: id, subject: subject)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEFF0F2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF426DC2).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.confirmation_number_outlined, size: 20, color: Color(0xFF426DC2)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Ticket #$id${dateLabel.isNotEmpty ? '  ·  $dateLabel' : ''}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF868686))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaq(String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
        iconColor: const Color(0xFF426DC2),
        collapsedIconColor: const Color(0xFF868686),
        children: [
          Text(answer, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFBEA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF008D5A).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 52, color: Color(0xFF008D5A)),
          const SizedBox(height: 12),
          const Text('Ticket Submitted!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF008D5A))),
          const SizedBox(height: 6),
          const Text(
            'We\'ve received your request and will respond within 24 hours.',
            style: TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _submitted = false),
            child: const Text('Submit another ticket', style: TextStyle(color: Color(0xFF426DC2), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Ticket Detail Screen ────────────────────────────────────────────────────

class TicketDetailView extends StatefulWidget {
  final String ticketId;
  final String subject;

  const TicketDetailView({super.key, required this.ticketId, required this.subject});

  @override
  State<TicketDetailView> createState() => _TicketDetailViewState();
}

class _TicketDetailViewState extends State<TicketDetailView> {
  Map<String, dynamic>? _ticket;
  bool _loading = true;
  String? _error;
  bool _sending = false;
  final TextEditingController _replyCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final message = _replyCtrl.text.trim();
    if (message.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final token = await StorageService().getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.supportTickets}/${widget.ticketId}/respond'),
        headers: {
          ...ApiConstants.getAuthHeaders(token ?? ''),
          'Content-Type': 'application/json',
        },
        body: json.encode({'message': message}),
      );
      debugPrint('🎫 [TicketReply] Status: ${response.statusCode}');
      debugPrint('🎫 [TicketReply] Body: ${response.body}');
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _replyCtrl.clear();
        await _loadTicket();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        final body = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message']?.toString() ?? 'Failed to send reply')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reply')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _loadTicket() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await StorageService().getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.supportTickets}/${widget.ticketId}'),
        headers: ApiConstants.getAuthHeaders(token ?? ''),
      ).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      debugPrint('🎫 [TicketDetail] Status: ${response.statusCode}');
      debugPrint('🎫 [TicketDetail] Body: ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body);
        final data = body['data'] ?? body['ticket'] ?? body;
        setState(() { _ticket = Map<String, dynamic>.from(data); _loading = false; });
      } else {
        setState(() { _error = 'Failed to load ticket'; _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load ticket'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8, right: 8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEFF0F2), width: 1.14),
              ),
              child: const Center(child: Icon(Icons.arrow_back, color: Color(0xFF426DC2), size: 20)),
            ),
          ),
        ),
        title: Text(
          'Ticket #${widget.ticketId}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF426DC2)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFCCCCCC)),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(fontSize: 14, color: Color(0xFF868686))),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadTicket, child: const Text('Retry', style: TextStyle(color: Color(0xFF426DC2)))),
                    ],
                  ),
                )
              : _buildBody(),
      bottomNavigationBar: _loading || _error != null ? null : _buildReplyBar(),
    );
  }

  Widget _buildBody() {
    final ticket = _ticket!;
    final subject = ticket['subject']?.toString() ?? widget.subject;
    final description = ticket['description']?.toString() ?? '';
    final status = ticket['status']?.toString() ?? 'open';
    final createdAt = ticket['created_at']?.toString() ?? '';
    final replies = ticket['replies'] as List? ?? ticket['messages'] as List? ?? [];

    final statusColor = switch (status.toLowerCase()) {
      'open' => const Color(0xFF426DC2),
      'closed' => const Color(0xFF868686),
      'resolved' => const Color(0xFF008D5A),
      _ => const Color(0xFFF09800),
    };

    return Column(
      children: [
        // Thin header bar: subject + status badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FF),
            border: Border(bottom: BorderSide(color: Color(0xFFEFF0F2))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
        ),

        // Chat messages
        Expanded(
          child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              // Original ticket message as first user bubble
              if (description.isNotEmpty)
                _buildBubble(
                  message: description,
                  isMe: true,
                  dateStr: createdAt,
                ),

              // Replies
              ...replies.map((r) {
                final reply = Map<String, dynamic>.from(r as Map);
                final message = reply['message']?.toString() ?? reply['body']?.toString() ?? '';
                final senderType = reply['sender_type']?.toString() ?? '';
                // sender_type "user" = sent by the user (right/blue)
                // sender_type "agent", "admin", "support", "staff" = received (left/grey)
                final isMe = senderType == 'user' || (reply['is_admin'] != true && senderType.isEmpty);
                final isSupport = !isMe;
                return _buildBubble(
                  message: message,
                  isMe: isMe,
                  dateStr: reply['created_at']?.toString() ?? '',
                  senderLabel: isSupport ? 'Support Team' : null,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBubble({
    required String message,
    required bool isMe,
    String dateStr = '',
    String? senderLabel,
  }) {
    String timeLabel = '';
    if (dateStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(dateStr).toLocal();
        timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF426DC2).withValues(alpha: 0.12),
              child: const Icon(Icons.support_agent_rounded, size: 16, color: Color(0xFF426DC2)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (senderLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(senderLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF426DC2))),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF426DC2) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : const Color(0xFF1A1A1A),
                      height: 1.45,
                    ),
                  ),
                ),
                if (timeLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(timeLabel, style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
                  ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFF0F2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyCtrl,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write a reply…',
                hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFEFF0F2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFEFF0F2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF426DC2)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendReply,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF426DC2),
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

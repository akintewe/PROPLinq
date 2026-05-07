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
      );
      if (!mounted) return;
      debugPrint('🎫 [Tickets] Status: ${response.statusCode}');
      debugPrint('🎫 [Tickets] Body: ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body);
        // Response: { data: { current_page, data: [...tickets] } }
        final outer = body['data'];
        final list = (outer is Map ? outer['data'] : outer) ?? [];
        setState(() {
          _tickets = List<Map<String, dynamic>>.from(
            (list as List).map((e) => Map<String, dynamic>.from(e)),
          );
          _loadingTickets = false;
        });
      } else {
        setState(() { _ticketsError = 'Failed to load tickets'; _loadingTickets = false; });
      }
    } catch (e) {
      if (!mounted) return;
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
    final id = ticket['id']?.toString() ?? '';
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

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await StorageService().getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.supportTickets}/${widget.ticketId}'),
        headers: ApiConstants.getAuthHeaders(token ?? ''),
      );
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

    String dateLabel = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateLabel = '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFF0F2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(dateLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF868686))),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(description, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.6)),
                ],
              ],
            ),
          ),

          if (replies.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Responses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 12),
            ...replies.map((r) {
              final reply = Map<String, dynamic>.from(r as Map);
              final message = reply['message']?.toString() ?? reply['body']?.toString() ?? '';
              final isAdmin = (reply['is_admin'] == true) || (reply['sender_type']?.toString() == 'admin');
              final replyDate = reply['created_at']?.toString() ?? '';
              String replyDateLabel = '';
              if (replyDate.isNotEmpty) {
                try {
                  final dt = DateTime.parse(replyDate).toLocal();
                  replyDateLabel = '${dt.day}/${dt.month}/${dt.year}';
                } catch (_) {}
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isAdmin ? const Color(0xFFEEF3FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEFF0F2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isAdmin ? 'Support Team' : 'You',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isAdmin ? const Color(0xFF426DC2) : Colors.black,
                            ),
                          ),
                          if (replyDateLabel.isNotEmpty) ...[
                            const Spacer(),
                            Text(replyDateLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF868686))),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.5)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

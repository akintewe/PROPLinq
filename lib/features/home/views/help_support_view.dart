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

class _HelpSupportViewState extends State<HelpSupportView> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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

      debugPrint('🎫 [Support] Status: ${response.statusCode}');
      debugPrint('🎫 [Support] Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() { _submitted = true; _isSubmitting = false; });
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
      ),
      body: SingleChildScrollView(
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

            // Submit ticket section
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

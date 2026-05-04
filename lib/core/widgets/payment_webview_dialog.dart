import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proplinq/core/services/payment_service.dart';

/// Opens a payment URL in Safari and shows a waiting screen.
///
/// If [reference] is provided the backend `/payments/verify` endpoint is
/// called when the user returns — payment is only confirmed as successful
/// if the server says so.  Without a reference the user's tap is trusted
/// (fallback for flows that don't return a reference).
Future<bool> showPaymentWebView({
  required BuildContext context,
  required String paymentUrl,
  String title = 'Complete Payment',
  String? reference,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PaymentWaitingDialog(
      paymentUrl: paymentUrl,
      title: title,
      reference: reference,
    ),
  );
  return result ?? false;
}

class _PaymentWaitingDialog extends StatefulWidget {
  final String paymentUrl;
  final String title;
  final String? reference;

  const _PaymentWaitingDialog({
    required this.paymentUrl,
    required this.title,
    this.reference,
  });

  @override
  State<_PaymentWaitingDialog> createState() => _PaymentWaitingDialogState();
}

class _PaymentWaitingDialogState extends State<_PaymentWaitingDialog> {
  bool _launching = true;
  bool _verifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _launchUrl();
  }

  Future<void> _launchUrl() async {
    try {
      final uri = Uri.parse(widget.paymentUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (mounted) setState(() => _launching = false);
  }

  Future<void> _confirmPayment() async {
    final nav = Navigator.of(context);

    // No reference — trust the user's tap (e.g. promote listing, pay-on-arrival)
    if (widget.reference == null) {
      nav.pop(true);
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    try {
      final response = await PaymentService().verify(reference: widget.reference);
      if (!mounted) return;

      if (response.success) {
        final data = response.data ?? {};
        final status = (data['status'] as String? ??
                data['data']?['status'] as String? ??
                '')
            .toLowerCase();

        // Accept any success-like status
        final isSuccess = status == 'success' ||
            status == 'successful' ||
            status == 'completed' ||
            status == 'paid' ||
            status.isEmpty; // backend returned 200 with no status field = success

        if (isSuccess) {
          nav.pop(true);
        } else {
          setState(() {
            _verifying = false;
            _errorMessage =
                'Payment not confirmed yet. Complete the payment in your browser, then try again.';
          });
        }
      } else {
        setState(() {
          _verifying = false;
          _errorMessage = response.message ?? 'Could not verify payment. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _errorMessage = 'Verification failed. Please try again.';
        });
      }
    }
  }

  Future<bool> _confirmCancel() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final nav = Navigator.of(context);
          final confirm = await _confirmCancel();
          if (confirm && mounted) nav.pop(false);
        }
      },
      child: Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              widget.title,
              style: const TextStyle(
                color: Color(0xFF426DC2),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF426DC2)),
              onPressed: () async {
                final nav = Navigator.of(context);
                final confirm = await _confirmCancel();
                if (confirm && mounted) nav.pop(false);
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF426DC2).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.open_in_browser_rounded,
                    size: 40,
                    color: Color(0xFF426DC2),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Redirecting to secure payment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B4A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _launching
                      ? 'Opening your browser...'
                      : 'Complete your payment in the browser, then tap the button below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                if (_launching || _verifying) ...[
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(color: Color(0xFF426DC2)),
                  if (_verifying) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Verifying payment...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
                if (!_launching && !_verifying) ...[
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF426DC2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "I've completed payment",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      final uri = Uri.parse(widget.paymentUrl);
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: const Text(
                      'Reopen payment page',
                      style: TextStyle(
                        color: Color(0xFF426DC2),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

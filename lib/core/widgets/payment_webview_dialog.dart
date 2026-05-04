import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a payment URL in the device's default browser (Safari on iOS)
/// and shows a waiting screen inside the app while the user completes payment.
///
/// Returns true if the user taps "I've completed payment", false if they cancel.
Future<bool> showPaymentWebView({
  required BuildContext context,
  required String paymentUrl,
  String title = 'Complete Payment',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PaymentWaitingDialog(
      paymentUrl: paymentUrl,
      title: title,
    ),
  );
  return result ?? false;
}

class _PaymentWaitingDialog extends StatefulWidget {
  final String paymentUrl;
  final String title;

  const _PaymentWaitingDialog({
    required this.paymentUrl,
    required this.title,
  });

  @override
  State<_PaymentWaitingDialog> createState() => _PaymentWaitingDialogState();
}

class _PaymentWaitingDialogState extends State<_PaymentWaitingDialog> {
  bool _launching = true;

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
                      : 'Complete your payment in the browser, then come back here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                if (_launching) ...[
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(color: Color(0xFF426DC2)),
                ],
                if (!_launching) ...[
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
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
}

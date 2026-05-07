import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A reusable full-screen WebView dialog for payment gateway pages.
///
/// Usage:
/// ```dart
/// final paid = await showPaymentWebView(
///   context: context,
///   paymentUrl: initResponse.authorizationUrl!,
/// );
/// if (paid) { /* handle success */ }
/// ```
Future<bool> showPaymentWebView({
  required BuildContext context,
  required String paymentUrl,
  String title = 'Complete Payment',
  String? reference,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PaymentWebViewDialog(
      paymentUrl: paymentUrl,
      title: title,
      reference: reference,
    ),
  );
  return result ?? false;
}

class PaymentWebViewDialog extends StatefulWidget {
  final String paymentUrl;
  final String title;
  final String? reference;

  const PaymentWebViewDialog({
    super.key,
    required this.paymentUrl,
    this.title = 'Complete Payment',
    this.reference,
  });

  @override
  State<PaymentWebViewDialog> createState() => _PaymentWebViewDialogState();
}

class _PaymentWebViewDialogState extends State<PaymentWebViewDialog> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            if (_isSuccessUrl(request.url)) {
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) Navigator.of(context).pop(true);
              });
            } else if (_isFailureUrl(request.url)) {
              if (mounted) Navigator.of(context).pop(false);
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isSuccessUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('status=successful') ||
        lower.contains('status=success') ||
        lower.contains('transaction_id=') ||
        lower.contains('/payment/success') ||
        (lower.contains('/callback') && lower.contains('success'));
  }

  bool _isFailureUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('status=failed') ||
        lower.contains('status=cancelled') ||
        lower.contains('/payment/failed') ||
        lower.contains('/payment/cancel');
  }

  Future<bool> _onWillPop() async {
    final confirm = await showDialog<bool>(
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
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final nav = Navigator.of(context);
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) nav.pop(false);
        }
      },
      child: Dialog.fullscreen(
        child: Scaffold(
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
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) nav.pop(false);
              },
            ),
          ),
          body: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                Container(
                  color: Colors.white,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF426DC2)),
                        SizedBox(height: 16),
                        Text(
                          'Redirecting to secure payment',
                          style: TextStyle(
                            color: Color(0xFF1A2B4A),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

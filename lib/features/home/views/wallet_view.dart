import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  final ApiService _apiService = ApiService();

  bool _isLoadingBalance = true;
  bool _isLoadingTransactions = true;
  double? _balance;
  String? _currency;
  List<Map<String, dynamic>> _transactions = [];
  String? _balanceError;
  String? _transactionsError;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    _fetchTransactions();
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _isLoadingBalance = true;
      _balanceError = null;
    });

    final response = await _apiService.get<dynamic>(
      '/agent/wallet/balance',
      requiresAuth: true,
      fromJson: (json) => json,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data;
      double? bal;
      String? cur;

      if (data is Map<String, dynamic>) {
        bal = _parseDouble(data['balance'] ?? data['amount'] ?? data['wallet_balance']);
        cur = data['currency']?.toString();
      }

      setState(() {
        _balance = bal;
        _currency = cur ?? 'NGN';
        _isLoadingBalance = false;
      });
    } else {
      setState(() {
        _balanceError = response.message ?? 'Failed to load balance';
        _isLoadingBalance = false;
      });
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
      _transactionsError = null;
    });

    final response = await _apiService.get<dynamic>(
      '/agent/wallet/transactions',
      requiresAuth: true,
      fromJson: (json) => json,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data;
      List<dynamic> list = [];

      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'] as List;
        } else if (data['transactions'] is List) {
          list = data['transactions'] as List;
        }
      }

      setState(() {
        _transactions = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoadingTransactions = false;
      });
    } else {
      setState(() {
        _transactionsError = response.message ?? 'Failed to load transactions';
        _isLoadingTransactions = false;
      });
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₦$formatted';
  }

  void _showFundWalletSheet() {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fund Wallet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the amount you want to add to your wallet.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF868686)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (₦)',
                    hintText: 'e.g. 5000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF426DC2), width: 2),
                    ),
                    prefixText: '₦ ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter an amount';
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 100) return 'Minimum amount is ₦100';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF426DC2), Color(0xFF63ADDC), Color(0xFF75CFEA)],
                        stops: [0.0, 1.0, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final amount = double.parse(amountController.text);
                          Navigator.of(ctx).pop();
                          _fundWallet(amount);
                        }
                      },
                      child: const Text(
                        'Proceed to Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fundWallet(double amount) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF426DC2)),
      ),
    );

    final response = await _apiService.post<dynamic>(
      '/agent/wallet/fund',
      body: {'amount': amount},
      requiresAuth: true,
      fromJson: (json) => json,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // close loading

    if (response.success && response.data != null) {
      final data = response.data;
      String? paymentUrl;

      if (data is Map<String, dynamic>) {
        paymentUrl = data['authorization_url']?.toString() ??
            data['link']?.toString() ??
            data['payment_url']?.toString() ??
            data['checkout_url']?.toString();
      }

      if (paymentUrl != null) {
        await _showPaymentWebView(paymentUrl, amount);
      } else {
        _showSuccessSnack('Wallet funded successfully!');
        _fetchBalance();
        _fetchTransactions();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Failed to initiate payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showPaymentWebView(String paymentUrl, double amount) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _WalletPaymentDialog(
        paymentUrl: paymentUrl,
        onSuccess: () {
          Navigator.of(ctx).pop();
          _showSuccessSnack('Wallet funded with ${_formatAmount(amount)}!');
          _fetchBalance();
          _fetchTransactions();
        },
        onCancelled: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
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
          padding: const EdgeInsets.only(left: 24.0, top: 8.0, bottom: 8.0, right: 8.0),
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
          'Wallet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF426DC2),
        onRefresh: () async {
          await Future.wait([_fetchBalance(), _fetchTransactions()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 32),
              _buildTransactionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF426DC2), Color(0xFF63ADDC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF426DC2).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Wallet Balance',
                style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w400),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fetchBalance,
                child: const Icon(Icons.refresh, color: Colors.white70, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingBalance)
            const SizedBox(
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else if (_balanceError != null)
            Text(
              'Unable to load',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
            )
          else
            Text(
              _balance != null ? _formatAmount(_balance!) : '₦0.00',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _showFundWalletSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF426DC2),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Fund Wallet',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        const SizedBox(height: 16),
        if (_isLoadingTransactions)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF426DC2)),
            ),
          )
        else if (_transactionsError != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    _transactionsError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _fetchTransactions,
                    child: const Text('Retry', style: TextStyle(color: Color(0xFF426DC2))),
                  ),
                ],
              ),
            ),
          )
        else if (_transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fund your wallet to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) => _buildTransactionTile(_transactions[index]),
          ),
      ],
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final type = tx['type']?.toString() ?? tx['transaction_type']?.toString() ?? '';
    final isCredit = type.toLowerCase().contains('credit') ||
        type.toLowerCase().contains('fund') ||
        type.toLowerCase().contains('deposit') ||
        (tx['direction']?.toString().toLowerCase() == 'credit');

    final amountRaw = tx['amount'] ?? tx['value'];
    final amount = _parseDouble(amountRaw);
    final description = tx['description']?.toString() ??
        tx['narration']?.toString() ??
        tx['note']?.toString() ??
        type;
    final dateRaw = tx['created_at']?.toString() ?? tx['date']?.toString() ?? '';
    final date = _formatDate(dateRaw);
    final status = tx['status']?.toString() ?? '';

    Color statusColor = Colors.grey;
    if (status.toLowerCase() == 'successful' || status.toLowerCase() == 'success' || status.toLowerCase() == 'completed') {
      statusColor = Colors.green;
    } else if (status.toLowerCase() == 'failed' || status.toLowerCase() == 'cancelled') {
      statusColor = Colors.red;
    } else if (status.toLowerCase() == 'pending') {
      statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCredit
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green[700] : Colors.red[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isNotEmpty ? description : (isCredit ? 'Credit' : 'Debit'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF868686)),
                    ),
                    if (status.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount != null
                ? '${isCredit ? '+' : '-'}${_formatAmount(amount)}'
                : '-',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isCredit ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _WalletPaymentDialog extends StatefulWidget {
  final String paymentUrl;
  final VoidCallback onSuccess;
  final VoidCallback onCancelled;

  const _WalletPaymentDialog({
    required this.paymentUrl,
    required this.onSuccess,
    required this.onCancelled,
  });

  @override
  State<_WalletPaymentDialog> createState() => _WalletPaymentDialogState();
}

class _WalletPaymentDialogState extends State<_WalletPaymentDialog> {
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
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkPaymentStatus(url);
          },
          onWebResourceError: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentStatus(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('success') ||
        lower.contains('status=successful') ||
        lower.contains('transaction_id=')) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) widget.onSuccess();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Fund Wallet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Payment?'),
                            content: const Text('Are you sure you want to cancel this payment?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  widget.onCancelled();
                                },
                                child: const Text('Yes, Cancel'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      Container(
                        color: Colors.white,
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFF426DC2)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

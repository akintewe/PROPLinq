import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/widgets/payment_webview_dialog.dart';

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
    if (!mounted) return;
    setState(() {
      _isLoadingBalance = true;
      _balanceError = null;
    });

    try {
      final token = await StorageService().getToken();
      final url = Uri.parse('${ApiConstants.apiBaseUrl}/agent/wallet/balance');
      final httpResponse = await http.get(url, headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (!mounted) return;

      debugPrint('💰 [Wallet] Balance status: ${httpResponse.statusCode}');
      debugPrint('💰 [Wallet] Balance body: ${httpResponse.body.substring(0, httpResponse.body.length.clamp(0, 500))}');

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        final jsonBody = json.decode(httpResponse.body);
        double? bal;
        String? cur;

        // Try data.balance, data.amount, top-level balance, wallet.balance
        Map<String, dynamic>? data;
        if (jsonBody['data'] is Map<String, dynamic>) {
          data = jsonBody['data'] as Map<String, dynamic>;
        } else if (jsonBody is Map<String, dynamic>) {
          data = jsonBody;
        }

        if (data != null) {
          bal = _parseDouble(
            data['balance'] ??
            data['amount'] ??
            data['wallet_balance'] ??
            (data['wallet'] is Map ? (data['wallet'] as Map)['balance'] : null),
          );
          cur = data['currency']?.toString() ??
              (data['wallet'] is Map ? (data['wallet'] as Map)['currency']?.toString() : null);
        }

        setState(() {
          _balance = bal;
          _currency = cur ?? 'NGN';
          _isLoadingBalance = false;
        });
      } else {
        final jsonBody = json.decode(httpResponse.body);
        setState(() {
          _balanceError = jsonBody['message']?.toString() ?? 'Failed to load balance';
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _balanceError = 'Failed to load balance';
        _isLoadingBalance = false;
      });
      debugPrint('💰 [Wallet] Balance error: $e');
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

    try {
      final token = await StorageService().getToken();
      final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.walletFund}');
      final httpResponse = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'amount': amount}),
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      debugPrint('💰 [Wallet] Fund status: ${httpResponse.statusCode}');
      debugPrint('💰 [Wallet] Fund body: ${httpResponse.body.substring(0, httpResponse.body.length.clamp(0, 600))}');

      final jsonBody = json.decode(httpResponse.body);

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        // Extract payment URL from response
        final data = jsonBody['data'] is Map ? jsonBody['data'] as Map<String, dynamic> : jsonBody as Map<String, dynamic>;
        final paymentUrl = data['authorization_url']?.toString() ??
            data['link']?.toString() ??
            data['payment_url']?.toString() ??
            data['checkout_url']?.toString();
        if (paymentUrl != null) {
          final paid = await showPaymentWebView(
            context: context,
            paymentUrl: paymentUrl,
            title: 'Fund Wallet',
          );
          if (mounted) {
            _fetchBalance();
            _fetchTransactions();
            if (paid) _showSuccessSnack('Wallet funded with ${_formatAmount(amount)}!');
          }
        } else {
          _showSuccessSnack('Wallet funded successfully!');
          _fetchBalance();
          _fetchTransactions();
        }
      } else {
        if (!mounted) return;
        // Extract validation errors if present
        String errorMsg = jsonBody['message']?.toString() ?? 'Failed to initiate payment';
        if (jsonBody['errors'] is Map) {
          final errs = <String>[];
          (jsonBody['errors'] as Map).forEach((_, v) {
            if (v is List) errs.addAll(v.map((e) => e.toString()));
          });
          if (errs.isNotEmpty) errorMsg = errs.join(', ');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Payout / Bank details ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchBanks() async {
    final token = await StorageService().getToken();
    final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.payoutBanks}');
    final res = await http.get(url, headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    debugPrint('🏦 [Banks] Status: ${res.statusCode}');
    debugPrint('🏦 [Banks] Body: ${res.body.substring(0, res.body.length.clamp(0, 400))}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = json.decode(res.body);
      List<dynamic> list = [];
      if (body['data'] is Map && body['data']['banks'] is List) {
        list = body['data']['banks'] as List;
      } else if (body['data'] is List) {
        list = body['data'] as List;
      } else if (body is List) {
        list = body as List;
      }
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  void _showPayoutSheet() async {
    // Show loading while fetching banks
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF426DC2))),
    );

    final banks = await _fetchBanks();

    if (!mounted) return;
    Navigator.of(context).pop();

    if (banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load bank list. Please try again.'), backgroundColor: Colors.red),
      );
      return;
    }

    final accountCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Map<String, dynamic>? selectedBank;
    bool isSaving = false;
    bool bankError = false;

    Future<void> pickBank(StateSetter setSheetState) async {
      final searchCtrl = TextEditingController();

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (pickerCtx) {
          List<Map<String, dynamic>> filtered = List.from(banks);
          return StatefulBuilder(
            builder: (pickerCtx, setPickerState) {
              return SizedBox(
                height: MediaQuery.of(pickerCtx).size.height * 0.75,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Select Bank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search bank name...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF868686)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF426DC2), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (q) {
                          setPickerState(() {
                            filtered = banks.where((b) {
                              final name = (b['name'] ?? b['bank_name'] ?? '').toString().toLowerCase();
                              return name.contains(q.toLowerCase());
                            }).toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final name = filtered[i]['name']?.toString() ?? filtered[i]['bank_name']?.toString() ?? '';
                          return ListTile(
                            title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            onTap: () {
                              setSheetState(() {
                                selectedBank = filtered[i];
                                bankError = false;
                              });
                              Navigator.of(pickerCtx).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payout Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
                    const SizedBox(height: 6),
                    const Text('Add your bank details to receive payouts.', style: TextStyle(fontSize: 14, color: Color(0xFF868686))),
                    const SizedBox(height: 24),

                    // Bank selector (tappable field)
                    GestureDetector(
                      onTap: () => pickBank(setSheetState),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: bankError ? Colors.red : const Color(0xFFBDBDBD)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedBank != null
                                    ? (selectedBank!['name'] ?? selectedBank!['bank_name'] ?? '').toString()
                                    : 'Select Bank',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: selectedBank != null ? Colors.black : const Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF868686)),
                          ],
                        ),
                      ),
                    ),
                    if (bankError)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 14),
                        child: Text('Please select a bank', style: TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                    const SizedBox(height: 16),

                    // Account number
                    TextFormField(
                      controller: accountCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: 'Account Number',
                        hintText: '10-digit account number',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF426DC2), width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Account number is required';
                        if (v.trim().length != 10) return 'Account number must be 10 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF426DC2), Color(0xFF63ADDC)]),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (selectedBank == null) {
                                    setSheetState(() => bankError = true);
                                    return;
                                  }
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => isSaving = true);

                                  final bank = selectedBank!;
                                  final bankName = bank['name']?.toString() ?? bank['bank_name']?.toString() ?? '';
                                  final bankCode = bank['code']?.toString() ?? bank['bank_code']?.toString() ?? '';
                                  final accountNumber = accountCtrl.text.trim();

                                  try {
                                    debugPrint('🏦 [Payout] Sending: bank_name=$bankName, bank_code=$bankCode, account_number=$accountNumber');
                                    final token = await StorageService().getToken();
                                    final url = Uri.parse('${ApiConstants.apiBaseUrl}/payouts/verify');
                                    final res = await http.post(url,
                                      headers: {
                                        'Accept': 'application/json',
                                        'Content-Type': 'application/json',
                                        if (token != null) 'Authorization': 'Bearer $token',
                                      },
                                      body: json.encode({
                                        'bank_name': bankName,
                                        'bank_code': bankCode,
                                        'account_number': accountNumber,
                                      }),
                                    );

                                    debugPrint('🏦 [Payout] Status: ${res.statusCode}');
                                    debugPrint('🏦 [Payout] Body: ${res.body}');

                                    if (!ctx.mounted) return;
                                    setSheetState(() => isSaving = false);

                                    if (res.statusCode >= 200 && res.statusCode < 300) {
                                      final resBody = json.decode(res.body);
                                      final data = resBody['data'] is Map ? resBody['data'] as Map<String, dynamic> : <String, dynamic>{};
                                      final accountName = data['account_name']?.toString() ?? '';

                                      // Show confirmation dialog with account name
                                      if (!ctx.mounted) return;
                                      final confirmed = await showDialog<bool>(
                                        context: ctx,
                                        builder: (dialogCtx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Text('Confirm Account', style: TextStyle(fontWeight: FontWeight.w700)),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Is this the correct account?', style: TextStyle(fontSize: 14, color: Color(0xFF868686))),
                                              const SizedBox(height: 16),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFECF0F9),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(accountName.isNotEmpty ? accountName : 'Account Holder', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
                                                    const SizedBox(height: 4),
                                                    Text(accountNumber, style: const TextStyle(fontSize: 13, color: Color(0xFF868686))),
                                                    const SizedBox(height: 2),
                                                    Text(bankName, style: const TextStyle(fontSize: 13, color: Color(0xFF868686))),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(dialogCtx).pop(false),
                                              child: const Text('Change', style: TextStyle(color: Color(0xFF868686))),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF426DC2),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => Navigator.of(dialogCtx).pop(true),
                                              child: const Text('Confirm'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        if (ctx.mounted) Navigator.of(ctx).pop();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Payout account saved successfully!'), backgroundColor: Colors.green),
                                          );
                                        }
                                      }
                                    } else {
                                      final body = json.decode(res.body);
                                      String errMsg = body['message']?.toString() ?? 'Failed to save account';
                                      if (errMsg.toLowerCase().contains('unable to verify')) {
                                        errMsg = 'Account not found. Please check your account number and bank, then try again.';
                                      }
                                      if (body['errors'] is Map) {
                                        final errs = <String>[];
                                        (body['errors'] as Map).forEach((_, v) {
                                          if (v is List) errs.addAll(v.map((e) => e.toString()));
                                        });
                                        if (errs.isNotEmpty) errMsg = errs.join(', ');
                                      }
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
                                      );
                                    }
                                  } catch (e) {
                                    if (!ctx.mounted) return;
                                    setSheetState(() => isSaving = false);
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Save Payout Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
              const SizedBox(height: 20),
              _buildPayoutAccountCard(),
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
            color: const Color(0xFF426DC2).withValues(alpha: 0.3),
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

  Widget _buildPayoutAccountCard() {
    return GestureDetector(
      onTap: _showPayoutSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFF0F2), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFECF0F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance_outlined, color: Color(0xFF426DC2), size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payout Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
                  SizedBox(height: 3),
                  Text('Add your bank details to receive payouts', style: TextStyle(fontSize: 12, color: Color(0xFF868686))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF868686), size: 20),
          ],
        ),
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
                          color: statusColor.withValues(alpha: 0.1),
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

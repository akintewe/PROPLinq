import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:proplinq/core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';
import '../../finance/views/complete_kyc_view.dart';
import '../../finance/views/agent_kyc_view.dart';

class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({super.key});

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isRequestingVerification = false;
  Map<String, dynamic>? _existingPayout;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _authService.getProfile();

      if (response.success && response.data != null) {
        setState(() {
          _currentUser = response.data;
          _existingPayout = response.data!.payout;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showMessage('Failed to load profile: ${response.message}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error loading profile: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBanks() async {
    final token = await StorageService().getToken();
    final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.payoutBanks}');
    final res = await http.get(url, headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = json.decode(res.body);
      List<dynamic> list = [];
      if (body['data'] is Map && body['data']['banks'] is List) {
        list = body['data']['banks'] as List;
      } else if (body['data'] is List) {
        list = body['data'] as List;
      } else if (body is List) {
        list = body;
      }
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  void _showPayoutSheet() async {
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

    final accountCtrl = TextEditingController(
      text: _existingPayout?['account_number']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    Map<String, dynamic>? selectedBank = _existingPayout != null &&
            (_existingPayout!['bank_name']?.toString().isNotEmpty == true)
        ? {'name': _existingPayout!['bank_name'], 'code': _existingPayout!['bank_code'] ?? ''}
        : null;
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
                              setSheetState(() { selectedBank = filtered[i]; bankError = false; });
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
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _existingPayout != null ? 'Update Payout Account' : 'Payout Account',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                    const SizedBox(height: 6),
                    const Text('Add your bank details to receive payouts.', style: TextStyle(fontSize: 14, color: Color(0xFF868686))),
                    const SizedBox(height: 24),
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
                                style: TextStyle(fontSize: 14, color: selectedBank != null ? Colors.black : const Color(0xFF9E9E9E)),
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
                          onPressed: isSaving ? null : () async {
                            if (selectedBank == null) { setSheetState(() => bankError = true); return; }
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => isSaving = true);

                            final bankName = selectedBank!['name']?.toString() ?? selectedBank!['bank_name']?.toString() ?? '';
                            final bankCode = selectedBank!['code']?.toString() ?? selectedBank!['bank_code']?.toString() ?? '';
                            final accountNumber = accountCtrl.text.trim();

                            try {
                              final token = await StorageService().getToken();
                              final url = Uri.parse('${ApiConstants.apiBaseUrl}/payouts/verify');
                              final res = await http.post(url,
                                headers: {
                                  'Accept': 'application/json',
                                  'Content-Type': 'application/json',
                                  if (token != null) 'Authorization': 'Bearer $token',
                                },
                                body: json.encode({'bank_name': bankName, 'bank_code': bankCode, 'account_number': accountNumber}),
                              );
                              if (!ctx.mounted) return;
                              setSheetState(() => isSaving = false);

                              if (res.statusCode >= 200 && res.statusCode < 300) {
                                final resBody = json.decode(res.body);
                                final data = resBody['data'] is Map ? resBody['data'] as Map<String, dynamic> : <String, dynamic>{};
                                final accountName = data['account_name']?.toString() ?? '';

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
                                          decoration: BoxDecoration(color: const Color(0xFFECF0F9), borderRadius: BorderRadius.circular(12)),
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
                                      TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Change', style: TextStyle(color: Color(0xFF868686)))),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF426DC2), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
                                    _fetchUserProfile();
                                  }
                                }
                              } else {
                                final body = json.decode(res.body);
                                String errMsg = body['message']?.toString() ?? 'Failed to save account';
                                if (errMsg.toLowerCase().contains('unable to verify')) {
                                  errMsg = 'Account not found. Please check your account number and bank, then try again.';
                                }
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg), backgroundColor: Colors.red));
                              }
                            } catch (e) {
                              if (!ctx.mounted) return;
                              setSheetState(() => isSaving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showVerificationCodeDialog({
    required String title,
    required String subtitle,
    required Function(String) onVerify,
  }) {
    final codeController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Enter verification code',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVerifying ? null : () async {
                if (codeController.text.trim().length != 6) {
                  _showMessage('Please enter a 6-digit code');
                  return;
                }

                setDialogState(() {
                  isVerifying = true;
                });

                try {
                  await onVerify(codeController.text.trim());
                  Navigator.pop(context);
                  await _fetchUserProfile(); // Refresh profile to update verification status
                } catch (e) {
                  setDialogState(() {
                    isVerifying = false;
                  });
                }
              },
              child: isVerifying 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPhoneVerification() async {
    setState(() {
      _isRequestingVerification = true;
    });

    try {
      final response = await _authService.requestPhoneVerification();
      
      if (response.success) {
        _showMessage('Verification code sent to your phone');
        _showVerificationCodeDialog(
          title: 'Verify Phone Number',
          subtitle: 'Enter the 6-digit code sent to ${_currentUser?.phoneNumber}',
          onVerify: (code) async {
            final verifyResponse = await _authService.verifyPhone(code);
            if (verifyResponse.success) {
              _showMessage('Phone number verified successfully!');
            } else {
              _showMessage('Verification failed: ${verifyResponse.message}');
              throw Exception(verifyResponse.message);
            }
          },
        );
      } else {
        _showMessage('Failed to send verification code: ${response.message}');
      }
    } catch (e) {
      _showMessage('Error requesting verification: $e');
    } finally {
      setState(() {
        _isRequestingVerification = false;
      });
    }
  }

  Future<void> _requestEmailVerification() async {
    setState(() {
      _isRequestingVerification = true;
    });

    try {
      final response = await _authService.requestNewEmailVerification();
      
      if (response.success) {
        _showMessage('Verification code sent to your email');
        _showVerificationCodeDialog(
          title: 'Verify Email Address',
          subtitle: 'Enter the 6-digit code sent to ${_currentUser?.email}',
          onVerify: (code) async {
            final verifyResponse = await _authService.verifyNewEmail(code);
            if (verifyResponse.success) {
              _showMessage('Email address verified successfully!');
            } else {
              _showMessage('Verification failed: ${verifyResponse.message}');
              throw Exception(verifyResponse.message);
            }
          },
        );
      } else {
        _showMessage('Failed to send verification code: ${response.message}');
      }
    } catch (e) {
      _showMessage('Error requesting verification: $e');
    } finally {
      setState(() {
        _isRequestingVerification = false;
      });
    }
  }

  String _getKycStatusText() {
    if (_currentUser?.kycStatus == true) {
      return 'Identity verified';
    } else if (_currentUser?.kycData != null) {
      return 'Verification in progress';
    } else {
      return 'Identity verification required';
    }
  }

  void _navigateToKycScreen() {
    if (_currentUser?.userType != 'home_seeker') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AgentKycView(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CompleteKycView(),
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('Failed to load user data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Email Verification
                      _buildVerificationItem(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        subtitle: _currentUser!.email,
                        isVerified: _currentUser!.emailVerifiedAt != null,
                        onVerify: _currentUser!.emailVerifiedAt == null 
                            ? _requestEmailVerification 
                            : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Phone Verification
                      _buildVerificationItem(
                        icon: Icons.phone_outlined,
                        title: 'Phone Number',
                        subtitle: _currentUser!.phoneNumber,
                        isVerified: _currentUser!.phoneVerifiedAt != null,
                        onVerify: _currentUser!.phoneVerifiedAt == null 
                            ? _requestPhoneVerification 
                            : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // KYC Verification
                      _buildVerificationItem(
                        icon: Icons.verified_user_outlined,
                        title: 'KYC Verification',
                        subtitle: _getKycStatusText(),
                        isVerified: _currentUser!.kycStatus == true,
                        onVerify: _currentUser!.kycStatus != true 
                            ? _navigateToKycScreen 
                            : null,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Additional account information
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildInfoItem(
                        icon: Icons.person_outline,
                        title: 'Full Name',
                        value: _currentUser!.fullName,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoItem(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        value: _currentUser!.location,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoItem(
                        icon: Icons.badge_outlined,
                        title: 'Account Type',
                        value: _currentUser!.userType != 'home_seeker' ? 'Agent' : 'Home Seeker',
                      ),

                      // Show agency details for agents
                      if (_currentUser!.userType != 'home_seeker') ...[
                        const SizedBox(height: 16),
                        _buildInfoItem(
                          icon: Icons.business_outlined,
                          title: 'Agency',
                          value: _currentUser!.agencyName ?? 'Not specified',
                        ),

                        const SizedBox(height: 16),
                        _buildInfoItem(
                          icon: Icons.work_outline,
                          title: 'Agent Type',
                          value: _currentUser!.agentType ?? 'Not specified',
                        ),
                      ],

                      // Payout account — iOS agents only (Android has it in Wallet)
                      if (Platform.isIOS && _currentUser!.userType != 'home_seeker') ...[
                        const SizedBox(height: 32),
                        const Text(
                          'Payout Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                        const SizedBox(height: 16),
                        _buildPayoutCard(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildPayoutCard() {
    final hasAccount = _existingPayout != null &&
        (_existingPayout!['account_number']?.toString().isNotEmpty == true);
    final bankName = _existingPayout?['bank_name']?.toString() ?? '';
    final accountNumber = _existingPayout?['account_number']?.toString() ?? '';
    final accountName = _existingPayout?['account_name']?.toString() ?? '';

    return GestureDetector(
      onTap: _showPayoutSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasAccount
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasAccount
                    ? Colors.green.withValues(alpha: 0.1)
                    : const Color(0xFF426DC2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasAccount ? Icons.account_balance : Icons.account_balance_outlined,
                color: hasAccount ? Colors.green : const Color(0xFF426DC2),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAccount) ...[
                    Text(
                      accountName.isNotEmpty ? accountName : bankName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bankName.isNotEmpty ? '$bankName · ' : ''}$accountNumber',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF868686)),
                    ),
                  ] else
                    const Text(
                      'Add bank details to receive payouts',
                      style: TextStyle(fontSize: 14, color: Color(0xFF868686)),
                    ),
                ],
              ),
            ),
            Icon(
              hasAccount ? Icons.edit_outlined : Icons.chevron_right,
              color: const Color(0xFF868686),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVerified,
    VoidCallback? onVerify,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isVerified ? Colors.green.withValues(alpha: 0.1) : const Color(0xFF426DC2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isVerified ? Colors.green : const Color(0xFF426DC2),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified && onVerify != null)
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: _isRequestingVerification ? null : onVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF426DC2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: _isRequestingVerification
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF426DC2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF426DC2),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
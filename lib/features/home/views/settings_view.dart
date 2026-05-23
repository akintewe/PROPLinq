import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/views/login_view.dart';
import 'guest_home_view.dart';
import 'account_settings_view.dart';
import 'notification_settings_view.dart';
import 'privacy_policy_view.dart';
import 'terms_and_conditions_view.dart';
import 'wallet_view.dart';
import 'help_support_view.dart';

class SettingsView extends StatefulWidget {
  final bool isAgent;
  
  const SettingsView({super.key, this.isAgent = false});
  
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (widget.isAgent && !Platform.isIOS) ...[
                        _buildWalletCard(),
                        const SizedBox(height: 24),
                      ],

                      _buildSettingItem(
                        iconPath: 'assets/icons/profile.svg',
                        iconColor: const Color(0xFF426DC2),
                        title: 'Account settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccountSettingsView(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildSettingItem(
                        iconPath: 'assets/icons/notification (3).svg',
                        iconColor: const Color(0xFF426DC2),
                        title: 'Notification settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationSettingsView(
                                isAgent: widget.isAgent,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildSettingItem(
                        iconPath: 'assets/icons/message-question.svg',
                        iconColor: const Color(0xFF426DC2),
                        title: 'Help & support',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HelpSupportView()),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildSettingItem(
                        iconPath: 'assets/icons/book.svg',
                        iconColor: const Color(0xFF426DC2),
                        title: 'Terms & condition',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsAndConditionsView(),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildSettingItem(
                        iconPath: 'assets/icons/lock (1).svg',
                        iconColor: const Color(0xFF426DC2),
                        title: 'Privacy policy',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyView(),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),

                      _buildSettingItem(
                        iconPath: 'assets/icons/trash (2).svg',
                        iconColor: Colors.red,
                        title: 'Delete account',
                        onTap: () {
                          _showDeleteAccountDialog(context);
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildSettingItem(
                        iconPath: 'assets/icons/login.svg',
                        iconColor: const Color(0xFF426DC2),
                        title: 'Log out',
                        onTap: () {
                          _showLogoutDialog(context);
                        },
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

  Widget _buildWalletCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WalletView()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Wallet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View balance, fund & transactions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String iconPath,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(60),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                iconColor,
                BlendMode.srcIn,
              ),
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.error_outline,
                  size: 24,
                  color: iconColor,
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Delete Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action is permanent and cannot be undone. All your data will be lost.',
            style: TextStyle(fontSize: 15, color: Color(0xFF666666), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF868686))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDeleteAccount();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF426DC2)),
      ),
    );

    try {
      final response = await _authService.deleteAccount();

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      if (response.success) {
        await _authService.clearUserData();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const GuestHomeView()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to delete account. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Log out'),
              content: _isLoggingOut 
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 16),
                        Text('Logging out...'),
                      ],
                    )
                  : const Text('Are you sure you want to log out?'),
              actions: _isLoggingOut 
                  ? [] 
                  : [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF868686)),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _handleLogout(context, setDialogState);
                        },
                        child: const Text(
                          'Log out',
                          style: TextStyle(color: Color(0xFF426DC2)),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, StateSetter setDialogState) async {
    setDialogState(() {
      _isLoggingOut = true;
    });

    setState(() {
      _isLoggingOut = true;
    });

    try {
      
      final response = await _authService.logout();
      
      
      if (response.errors != null && response.errors!.isNotEmpty) {
      }

      // Close dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to login screen regardless of API response
      // because AuthService.logout() clears local storage anyway
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GuestHomeView()),
          (route) => false, // Remove all previous routes
        );
      }


    } catch (e) {
      
      // Close dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Even if API fails, clear local data and navigate to login
      await _authService.clearUserData();
      
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
      
      
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/views/login_view.dart';
import 'account_settings_view.dart';

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
                        onTap: () {},
                      ),
                      
                        const SizedBox(height: 20),
                      
                      _buildSettingItem(
                        iconPath: 'assets/icons/message-question.svg',
                        iconColor: const Color(0xFF426DC2),
                        title: 'Help & support',
                        onTap: () {},
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildSettingItem(
                        iconPath: 'assets/icons/book.svg',
                        iconColor: const Color(0xFF426DC2),
                        title: 'Terms & condition',
                        onTap: () {},
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildSettingItem(
                        iconPath: 'assets/icons/lock (1).svg',
                        iconColor: const Color(0xFF426DC2),
                        title: 'Privacy policy',
                        onTap: () {},
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
      print('🔄 Logging out user...');
      
      final response = await _authService.logout();
      
      print('📋 Logout Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');
      
      if (response.errors != null && response.errors!.isNotEmpty) {
        print('❌ Errors: ${response.errors}');
      }

      // Close dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to login screen regardless of API response
      // because AuthService.logout() clears local storage anyway
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false, // Remove all previous routes
        );
      }

      print('✅ User logged out and navigated to login screen');

    } catch (e) {
      print('❌ Logout error: $e');
      
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
      
      print('✅ User logged out locally and navigated to login screen');
      
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }
} 
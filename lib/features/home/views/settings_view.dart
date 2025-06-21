import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';

class SettingsView extends StatelessWidget {
  final bool isAgent;
  
  const SettingsView({super.key, this.isAgent = false});

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
                        onTap: () {},
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
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
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
              onPressed: () {
                Navigator.of(context).pop();
                // Handle logout logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
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
  }
} 
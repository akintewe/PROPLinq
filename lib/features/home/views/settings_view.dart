import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  final bool isAgent;
  
  const SettingsView({super.key, this.isAgent = false});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _locationAccess = true;

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
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notifications Section
                      _buildSectionHeader('Notifications'),
                      _buildSwitchItem(
                        title: 'Push Notifications',
                        subtitle: 'Receive alerts about new properties and messages',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                        },
                      ),
                      _buildSwitchItem(
                        title: 'Email Notifications',
                        subtitle: 'Get updates via email',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() {
                            _emailNotifications = value;
                          });
                        },
                      ),
                      _buildSwitchItem(
                        title: 'SMS Notifications',
                        subtitle: 'Receive important updates via SMS',
                        value: _smsNotifications,
                        onChanged: (value) {
                          setState(() {
                            _smsNotifications = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Privacy Section
                      _buildSectionHeader('Privacy'),
                      _buildSwitchItem(
                        title: 'Location Access',
                        subtitle: 'Allow app to access your location for better property recommendations',
                        value: _locationAccess,
                        onChanged: (value) {
                          setState(() {
                            _locationAccess = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // App Settings Section
                      _buildSectionHeader('App Settings'),
                      _buildMenuItem(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.color_lens_outlined,
                        title: 'Theme',
                        subtitle: 'Light',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.storage_outlined,
                        title: 'Clear Cache',
                        subtitle: 'Free up storage space',
                        onTap: () {},
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Support Section
                      _buildSectionHeader('Support'),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.feedback_outlined,
                        title: 'Send Feedback',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: 'About PropLinq',
                        onTap: () {},
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Account Section
                      _buildSectionHeader('Account'),
                      _buildMenuItem(
                        icon: Icons.delete_outline,
                        title: 'Delete Account',
                        onTap: () {},
                        isDestructive: true,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFECF0F9),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF868686),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF426DC2),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFECF0F9),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDestructive ? Colors.red : const Color(0xFF426DC2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF868686),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDestructive ? Colors.red : const Color(0xFF868686),
            ),
          ],
        ),
      ),
    );
  }
} 
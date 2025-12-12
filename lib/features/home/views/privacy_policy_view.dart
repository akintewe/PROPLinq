import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyView extends StatefulWidget {
  const PrivacyPolicyView({super.key});

  @override
  State<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  String _policyContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      // Load the privacy policy content from the markdown file
      final String content = await rootBundle.loadString('privacypolicy.md');
      setState(() {
        _policyContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _policyContent = '''
# Proplinq Terms & Conditions

Last updated: March 2025

Please read these Terms carefully before using our platform. By accessing or using Proplinq, you agree to be bound by these Terms. If you do not agree, please do not use our services.

## 1. Acceptance of Terms

By creating an account, browsing listings, or using any Proplinq service, you acknowledge that you have read, understood, and agreed to these Terms and our Privacy Policy.

## 2. License to Use

We grant you a limited, non-transferable, non-exclusive license to use the Proplinq platform for personal or business purposes, strictly in accordance with these Terms. You may not:
• Modify, copy, or resell platform content without permission
• Attempt to reverse-engineer the platform or its software
• Remove any copyright or proprietary notices
• Use automated systems (bots, scrapers, crawlers) to extract platform data

## 3. User Accounts and Verification

To access certain features, you must create an account. By registering, you agree to:
• Provide accurate and complete information
• Maintain and update your account details
• Keep your login credentials secure
• Accept responsibility for all activities under your account
• Notify us immediately of any unauthorized access

### Agent & Hospitality Provider Verification:
All real estate agents, property owners, and hospitality partners must undergo KYC and verification, including proof of identity, licenses, and business documentation.

## 4. Property Listings and Content

By submitting listings or content to Proplinq, you agree to:
• Provide truthful and accurate property details
• Only list properties you are legally authorized to represent
• Ensure descriptions, images, and availability are up to date
• Comply with housing, advertising, and non-discrimination laws
• Remove or update listings when no longer available

You grant Proplinq a license to use, display, and promote your listings in connection with our services.

## 5. Payment Protection and Transactions

Proplinq provides payment protection features to promote trust and safety:
• Hotels & Shortlets: Payments are processed via Proplinq Wallet and only released after booking confirmation.
• Rentals & Sales: Payments are made directly between users and verified agents/owners. Proplinq does not hold or guarantee these payments.
• Disputes: Proplinq offers mediation for booking disputes. Unresolved matters may be referred to third-party arbitration.
• Refunds: Refunds are available for fraudulent or misrepresented hotel/shortlet bookings, subject to review.

⚠️ Disclaimer: While we verify listings, Proplinq does not guarantee the final condition of properties. Users are responsible for conducting due diligence before entering contracts.

## 6. Prohibited Uses

You agree not to use Proplinq to:
• Violate Nigerian or international laws
• Post false, misleading, or fraudulent content
• Engage in scams, spamming, or harassment
• Upload viruses or malicious software
• Interfere with security features or platform integrity

## 7. Termination of Accounts

Proplinq reserves the right to suspend or permanently terminate accounts that violate these Terms, engage in fraudulent activity, or harm the platform's reputation.

## 8. Limitation of Liability

To the maximum extent permitted by law:
• Proplinq is not liable for indirect, incidental, or consequential damages arising from use of the platform.
• Proplinq does not guarantee uninterrupted access to the platform.
• Users are responsible for their own property due diligence and legal obligations.

## 9. Privacy Policy

Your use of Proplinq is also governed by our Privacy Policy, which explains how we collect, use, and protect your personal data.

## 10. Modifications

We may update these Terms at any time. Continued use of Proplinq after changes are posted means you accept the updated Terms.

## 11. Governing Law

These Terms are governed by the laws of the Federal Republic of Nigeria. Any disputes will be resolved under Nigerian jurisdiction.
''';
        _isLoading = false;
      });
    }
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
                border: Border.all(
                  color: const Color(0xFFEFF0F2),
                  width: 1.14,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF426DC2),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF426DC2),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Proplinq Terms & Conditions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Last updated: March 2025',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF868686),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Content
                  Text(
                    _policyContent,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Footer note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Color(0xFF426DC2),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'For questions about these terms, please contact our support team.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

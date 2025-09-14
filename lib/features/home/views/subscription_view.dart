import 'package:flutter/material.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  String _selectedPlan = 'starter'; // 'free', 'starter', 'smart', 'pro', 'enterprise'

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
          'Subscription',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Center(
              child: Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            const Text(
              'Select the perfect plan to grow your real estate business with Proplinq.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Free Plan
            _buildPlanCard(
              planType: 'free',
              title: 'Free Plan',
              price: '₦0',
              description: 'For landlords or new agents testing Proplinq.',
              features: [
                'Upload 2 properties',
                'Listed in general search (no promotion)',
                'Basic profile',
                'Access to limited inquiries',
              ],
              isSelected: _selectedPlan == 'free',
              onTap: () => setState(() => _selectedPlan = 'free'),
            ),
            
            const SizedBox(height: 16),
            
            // Starter Agent Plan
            _buildPlanCard(
              planType: 'starter',
              title: 'Starter Agent',
              price: '₦5,000/month',
              description: 'For solo agents who want credibility.',
              features: [
                'Upload up to 10 properties',
                'Verified Agent Badge (trust boost)',
                'Basic analytics (views & inquiries count)',
                'Standard search placement',
                'In-app chat support',
                'Video upload',
              ],
              isSelected: _selectedPlan == 'starter',
              onTap: () => setState(() => _selectedPlan = 'starter'),
            ),
            
            const SizedBox(height: 16),
            
            // Smart Growth Plan
            _buildPlanCard(
              planType: 'smart',
              title: 'Smart Growth',
              price: '₦10,000/month',
              description: 'For small & mid-size agencies.',
              features: [
                'Unlimited property uploads',
                '2 promoted listings per month (top placement)',
                'Verified Agent/Company Badge',
                'Lead Dashboard (track inquiries, calls, interest per property)',
                'Analytics: top-performing listings + demand by location',
                'Video upload',
                'Priority customer support',
              ],
              isSelected: _selectedPlan == 'smart',
              onTap: () => setState(() => _selectedPlan = 'smart'),
            ),
            
            const SizedBox(height: 16),
            
            // Pro Partner Plan
            _buildPlanCard(
              planType: 'pro',
              title: 'Pro Partner',
              price: '₦15,000/month',
              description: 'For professional agencies who want branding & wider reach.',
              features: [
                'Unlimited property uploads',
                '5 promoted listings per month',
                'Verified Company Badge',
                'Premium analytics (market heatmap, conversion trends)',
                '360° Virtual Tour/video upload Support (1 property/month)',
                'Featured in Proplinq\'s social media campaigns & Realtor Spotlight',
                'Priority listing verification',
              ],
              isSelected: _selectedPlan == 'pro',
              onTap: () => setState(() => _selectedPlan = 'pro'),
            ),
            
            const SizedBox(height: 16),
            
            // Enterprise Plus Plan
            _buildPlanCard(
              planType: 'enterprise',
              title: 'Enterprise Plus',
              price: '₦25,000/month',
              description: 'For large real estate firms, developers & top agencies.',
              features: [
                'Unlimited property uploads',
                'Unlimited promoted listings (always top search placement)',
                'Verified Enterprise Badge + dedicated account manager',
                'Advanced analytics + AI-powered lead recommendations',
                'Monthly Proplinq in-app ads (exclusive featured exposure)',
                'Unlimited 360° Virtual Tour/video upload Support (basic tours for all listings)',
                'Featured in nationwide Proplinq campaigns',
              ],
              isSelected: _selectedPlan == 'enterprise',
              onTap: () => setState(() => _selectedPlan = 'enterprise'),
            ),
            
            const SizedBox(height: 32),
            
            // Hotel & Shortlet Bookings
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE8EEFF),
                  width: 1,
                ),
              ),
              child: const Text(
                'Hotel & Shortlet Bookings: Proplinq charges a 10% commission on each successful booking.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF426DC2),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Subscribe Button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF426DC2),
                    Color(0xFF63ADDC),
                    Color(0xFF75CFEA),
                  ],
                  stops: [0.0, 1.0, 1.0],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ElevatedButton(
                onPressed: () {
                  _showSubscriptionConfirmation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Center(
                  child: Text(
                    _getButtonText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planType,
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF426DC2) : const Color(0xFFE8EEFF),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF426DC2).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF426DC2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF426DC2) : const Color(0xFFCCCCCC),
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF426DC2) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Features
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF426DC2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }


  String _getButtonText() {
    switch (_selectedPlan) {
      case 'free':
        return 'Continue with Free Plan';
      case 'starter':
        return 'Subscribe to Starter Agent';
      case 'smart':
        return 'Subscribe to Smart Growth';
      case 'pro':
        return 'Subscribe to Pro Partner';
      case 'enterprise':
        return 'Subscribe to Enterprise Plus';
      default:
        return 'Subscribe';
    }
  }

  String _getPlanName() {
    switch (_selectedPlan) {
      case 'free':
        return 'Free Plan';
      case 'starter':
        return 'Starter Agent';
      case 'smart':
        return 'Smart Growth';
      case 'pro':
        return 'Pro Partner';
      case 'enterprise':
        return 'Enterprise Plus';
      default:
        return 'Plan';
    }
  }

  String _getPlanPrice() {
    switch (_selectedPlan) {
      case 'free':
        return '₦0';
      case 'starter':
        return '₦5,000/month';
      case 'smart':
        return '₦10,000/month';
      case 'pro':
        return '₦15,000/month';
      case 'enterprise':
        return '₦25,000/month';
      default:
        return '₦0';
    }
  }

  void _showSubscriptionConfirmation() {
    final selectedPlanName = _getPlanName();
    final selectedPrice = _getPlanPrice();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Subscription',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedPlan == 'free' 
                  ? 'You are about to continue with the $selectedPlanName.'
                  : 'You are about to subscribe to the $selectedPlanName for $selectedPrice.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Do you want to proceed?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF426DC2),
                    Color(0xFF63ADDC),
                    Color(0xFF75CFEA),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSuccessMessage(selectedPlanName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _selectedPlan == 'free' ? 'Continue' : 'Subscribe',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessMessage(String planName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully subscribed to $planName Plan!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Navigate back to profile
    Navigator.of(context).pop();
  }
}

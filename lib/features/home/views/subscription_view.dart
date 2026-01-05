import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _subscriptionPlans = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedPlanType; // Will be set from API data

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionPlans();
  }

  Future<void> _fetchSubscriptionPlans() async {
    try {
      print('🟣 [SubscriptionView] Fetching subscription plans...');
      print('🟣 [SubscriptionView] Endpoint: ${ApiConstants.subscriptionPlans}');
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _apiService.get<dynamic>(
        ApiConstants.subscriptionPlans,
        requiresAuth: true,
        fromJson: (json) {
        // Log the raw json structure
        print('🟣 [SubscriptionView] Raw JSON in fromJson:');
        print('   Type: ${json.runtimeType}');
        print('   Content: $json');
        if (json is Map) {
          print('   Keys: ${json.keys.toList()}');
        }
          
          // Return the whole json so we can access 'data' field if it's a List
          return json;
        },
      );

      print('🟣 [SubscriptionView] Response received:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Message: ${response.message}');
      print('   - Data type: ${response.data?.runtimeType}');
      print('   - Data is null: ${response.data == null}');

      if (response.success && response.data != null) {
        final data = response.data!;
        print('🟣 [SubscriptionView] Processing response data...');
        print('   - Data type: ${data.runtimeType}');
        
        // Log the full data structure
        print('🟣 [SubscriptionView] Full data content:');
        print('   $data');
        
        // Handle different response structures
        List<dynamic> plansData = [];
        if (data is Map<String, dynamic>) {
          print('   - Data is Map with keys: ${data.keys.toList()}');
          print('   - Map entries: ${data.entries.map((e) => '${e.key}: ${e.value.runtimeType}').toList()}');
          
          // Try to find plans in various possible keys
          if (data.containsKey('data')) {
            print('   - Found "data" key in Map');
            if (data['data'] is List) {
              plansData = data['data'] as List<dynamic>;
              print('   - Extracted ${plansData.length} plans from data.data (List)');
            } else if (data['data'] is Map && (data['data'] as Map).containsKey('data')) {
              final nestedData = (data['data'] as Map<String, dynamic>)['data'];
              if (nestedData is List) {
                plansData = nestedData;
                print('   - Extracted ${plansData.length} plans from nested data.data');
              }
            }
          } else if (data.containsKey('plans')) {
            print('   - Found "plans" key in Map');
            if (data['plans'] is List) {
              plansData = data['plans'] as List<dynamic>;
              print('   - Extracted ${plansData.length} plans from plans (List)');
            }
          } else if (data.containsKey('subscription_plans')) {
            print('   - Found "subscription_plans" key in Map');
            if (data['subscription_plans'] is List) {
              plansData = data['subscription_plans'] as List<dynamic>;
              print('   - Extracted ${plansData.length} plans from subscription_plans (List)');
            }
          } else {
            // Check if any value in the map is a List
            print('   - Checking if any value is a List...');
            for (var entry in data.entries) {
              print('   - Key: ${entry.key}, Value type: ${entry.value.runtimeType}');
              if (entry.value is List) {
                plansData = entry.value as List<dynamic>;
                print('   - Found List in key "${entry.key}" with ${plansData.length} items');
                break;
              }
            }
            
            if (plansData.isEmpty) {
              print('   - No List found in Map, checking Map values...');
              // Maybe the plans are nested deeper
              for (var entry in data.entries) {
                if (entry.value is Map) {
                  final nestedMap = entry.value as Map<String, dynamic>;
                  print('   - Checking nested Map "${entry.key}" with keys: ${nestedMap.keys.toList()}');
                  if (nestedMap.containsKey('data') && nestedMap['data'] is List) {
                    plansData = nestedMap['data'] as List<dynamic>;
                    print('   - Found plans in nested Map "${entry.key}.data"');
                    break;
                  }
                }
              }
            }
          }
        } else if (data is List) {
          plansData = data;
          print('   - Using data directly as List (${plansData.length} items)');
        }

        if (plansData.isNotEmpty) {
          print('🟣 [SubscriptionView] First plan structure:');
          print('   ${plansData[0]}');
          print('🟣 [SubscriptionView] All plans:');
          for (var i = 0; i < plansData.length; i++) {
            print('   Plan $i: ${plansData[i]}');
          }
        } else {
          print('⚠️ [SubscriptionView] No plans data extracted from response');
          print('   - Attempting to log all possible structures...');
          if (data is Map) {
            data.forEach((key, value) {
              print('   - $key: ${value.runtimeType} = $value');
            });
          }
        }

        final plans = plansData
            .map((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return <String, dynamic>{};
            })
            .where((item) => item.isNotEmpty)
            .toList();

        print('✅ [SubscriptionView] Successfully parsed ${plans.length} subscription plans');
        
          setState(() {
          _subscriptionPlans = plans;
          _isLoading = false;
          // Select first plan by default if available
          if (plans.isNotEmpty && _selectedPlanType == null) {
            _selectedPlanType = plans[0]['slug']?.toString() ?? 
                               plans[0]['plan_type']?.toString() ?? 
                               plans[0]['type']?.toString() ?? 
                               plans[0]['id']?.toString();
          }
        });
        
        print('🟣🟣🟣 [SubscriptionView] ========================================');
      } else {
        print('❌ [SubscriptionView] Failed to fetch subscription plans');
        print('   - Success: ${response.success}');
        print('   - Status Code: ${response.statusCode}');
        print('   - Message: ${response.message}');
        print('🟣🟣🟣 [SubscriptionView] ========================================');
        
        setState(() {
          _errorMessage = response.message ?? 'Failed to load subscription plans';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ [SubscriptionView] Error fetching subscription plans: $e');
      print('❌ [SubscriptionView] Stack trace: $stackTrace');
      print('🟣🟣🟣 [SubscriptionView] ========================================');
      
      setState(() {
        _errorMessage = 'Error loading subscription plans: ${e.toString()}';
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
          'Subscription',
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
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchSubscriptionPlans,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF426DC2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
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
                      
                      // Dynamic Plan Cards from API
                      if (_subscriptionPlans.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No subscription plans available',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._subscriptionPlans.asMap().entries.map((entry) {
                          final index = entry.key;
                          final plan = entry.value;
                          // Use slug as plan_type for payment API
                          final planType = plan['slug']?.toString() ?? 
                                        plan['plan_type']?.toString() ?? 
                                        plan['type']?.toString() ?? 
                                        plan['id']?.toString() ?? 
                                        'plan_$index';
                          // Use display_name or name for title
                          final title = plan['display_name']?.toString() ?? 
                                      plan['name']?.toString() ?? 
                                      plan['title']?.toString() ?? 
                                      plan['plan_name']?.toString() ?? 
                                      'Plan ${index + 1}';
                          final price = _formatPrice(plan);
                          final description = plan['description']?.toString() ?? 
                                           plan['subtitle']?.toString() ?? 
                                           '';
                          final features = _extractFeatures(plan);
                          
                          return Column(
                            children: [
                              if (index > 0) const SizedBox(height: 16),
                              _buildPlanCard(
                                planType: planType,
                                title: title,
                                price: price,
                                description: description,
                                features: features,
                                isSelected: _selectedPlanType == planType,
                                onTap: () => setState(() => _selectedPlanType = planType),
                              ),
                            ],
                          );
                        }).toList(),
            
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


  String _formatPrice(Map<String, dynamic> plan) {
    final price = plan['price'] ?? plan['amount'] ?? plan['cost'];
    final currency = plan['currency']?.toString() ?? 'NGN';
    final period = plan['period']?.toString() ?? 
                  plan['billing_period']?.toString() ?? 
                  plan['duration']?.toString() ?? 
                  'month';
    
    if (price == null) {
      return 'Contact us';
    }
    
    final priceValue = price is String ? double.tryParse(price) : (price is num ? price.toDouble() : null);
    
    if (priceValue == null) {
      return 'Contact us';
    }
    
    if (priceValue == 0) {
      return 'Free';
    }
    
    // Format currency symbol
    String currencySymbol = '₦';
    if (currency == 'USD') currencySymbol = '\$';
    if (currency == 'EUR') currencySymbol = '€';
    if (currency == 'GBP') currencySymbol = '£';
    
    final formattedPrice = priceValue.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    return '$currencySymbol$formattedPrice/$period';
  }

  List<String> _extractFeatures(Map<String, dynamic> plan) {
    // Try different possible keys for features
    if (plan['features'] != null) {
      if (plan['features'] is List) {
        return (plan['features'] as List)
            .map((f) => f.toString())
            .where((f) => f.isNotEmpty)
            .toList();
      } else if (plan['features'] is String) {
        // If features is a string, split by newlines or commas
        return plan['features']
            .toString()
            .split(RegExp(r'[\n,;]'))
            .map((f) => f.trim())
            .where((f) => f.isNotEmpty)
            .toList();
      }
    }
    
    // Try 'benefits' or 'included' as alternatives
    if (plan['benefits'] != null && plan['benefits'] is List) {
      return (plan['benefits'] as List)
          .map((f) => f.toString())
          .where((f) => f.isNotEmpty)
          .toList();
    }
    
    if (plan['included'] != null && plan['included'] is List) {
      return (plan['included'] as List)
          .map((f) => f.toString())
          .where((f) => f.isNotEmpty)
          .toList();
    }
    
    // Return empty list if no features found
    return [];
  }

  String _getButtonText() {
    if (_selectedPlanType == null || _subscriptionPlans.isEmpty) {
      return 'Subscribe';
    }
    
    final selectedPlan = _subscriptionPlans.firstWhere(
      (plan) => (plan['slug']?.toString() ?? 
                 plan['plan_type']?.toString() ?? 
                 plan['type']?.toString() ?? 
                 plan['id']?.toString()) == _selectedPlanType,
      orElse: () => _subscriptionPlans[0],
    );
    
    final planName = selectedPlan['display_name']?.toString() ?? 
                    selectedPlan['name']?.toString() ?? 
                    selectedPlan['title']?.toString() ?? 
                    selectedPlan['plan_name']?.toString() ?? 
                    'Plan';
    
    final price = _formatPrice(selectedPlan);
    if (price == 'Free' || price == 'Contact us') {
      return 'Continue with $planName';
    }
    
    return 'Subscribe to $planName';
  }

  String _getPlanName() {
    if (_selectedPlanType == null || _subscriptionPlans.isEmpty) {
      return 'Plan';
    }
    
    final selectedPlan = _subscriptionPlans.firstWhere(
      (plan) => (plan['slug']?.toString() ?? 
                 plan['plan_type']?.toString() ?? 
                 plan['type']?.toString() ?? 
                 plan['id']?.toString()) == _selectedPlanType,
      orElse: () => _subscriptionPlans[0],
    );
    
    return selectedPlan['display_name']?.toString() ?? 
           selectedPlan['name']?.toString() ?? 
           selectedPlan['title']?.toString() ?? 
           selectedPlan['plan_name']?.toString() ?? 
           'Plan';
  }

  String _getPlanPrice() {
    if (_selectedPlanType == null || _subscriptionPlans.isEmpty) {
      return '₦0';
    }
    
    final selectedPlan = _subscriptionPlans.firstWhere(
      (plan) => (plan['slug']?.toString() ?? 
                 plan['plan_type']?.toString() ?? 
                 plan['type']?.toString() ?? 
                 plan['id']?.toString()) == _selectedPlanType,
      orElse: () => _subscriptionPlans[0],
    );
    
    return _formatPrice(selectedPlan);
  }

  Map<String, dynamic>? _getSelectedPlan() {
    if (_selectedPlanType == null || _subscriptionPlans.isEmpty) {
      return null;
    }
    
    return _subscriptionPlans.firstWhere(
      (plan) => (plan['slug']?.toString() ?? 
                 plan['plan_type']?.toString() ?? 
                 plan['type']?.toString() ?? 
                 plan['id']?.toString()) == _selectedPlanType,
      orElse: () => _subscriptionPlans[0],
    );
  }

  void _showSubscriptionConfirmation() {
    final selectedPlan = _getSelectedPlan();
    if (selectedPlan == null) return;
    
    final selectedPlanName = _getPlanName();
    final selectedPrice = _getPlanPrice();
    final isFree = selectedPrice == 'Free' || selectedPrice == 'Contact us';
    
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
                isFree
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
                  if (isFree) {
                    _showSuccessMessage(selectedPlanName);
                  } else {
                    _processPayment(selectedPlan);
                  }
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
                  isFree ? 'Continue' : 'Proceed to Payment',
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

  Future<void> _processPayment(Map<String, dynamic> plan) async {
    try {
      final planSlug = plan['slug']?.toString();
      if (planSlug == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid plan selected'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('💳 [SubscriptionView] Processing payment...');
      print('   - Plan slug: $planSlug');
      print('   - Payment method: flutterwave');
      print('   - Endpoint: ${ApiConstants.paySubscription}');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF426DC2),
            ),
          );
        },
      );

      final response = await _apiService.post<dynamic>(
        ApiConstants.paySubscription,
        body: {
          'plan_type': planSlug,
          'payment_method': 'flutterwave',
        },
        requiresAuth: true,
        fromJson: (json) => json,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      print('💳 [SubscriptionView] Payment response:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Message: ${response.message}');
      print('   - Data: ${response.data}');

      if (response.success) {
          // Check if response contains payment URL or redirect
          if (response.data != null && response.data is Map) {
            final data = response.data as Map<String, dynamic>;
            
            // Check for payment URL (Flutterwave typically returns authorization_url or link)
            if (data.containsKey('authorization_url') || data.containsKey('link') || data.containsKey('payment_url')) {
              final paymentUrl = data['authorization_url'] ?? 
                               data['link'] ?? 
                               data['payment_url'];
              
              print('💳 [SubscriptionView] Payment URL received: $paymentUrl');
              
              // Show payment WebView dialog
              if (mounted) {
                await _showPaymentWebView(paymentUrl);
              }
            } else {
              // Payment processed directly
              if (mounted) {
                _showSuccessMessage(_getPlanName());
              }
            }
          } else {
            // Payment successful
            if (mounted) {
              _showSuccessMessage(_getPlanName());
            }
          }
      } else {
        // Payment failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Payment failed. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ [SubscriptionView] Payment error: $e');
      print('❌ [SubscriptionView] Stack trace: $stackTrace');
      
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showPaymentWebView(String paymentUrl) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentWebViewDialog(
        paymentUrl: paymentUrl,
        onPaymentComplete: () {
          // Close the dialog
          Navigator.of(context).pop();
          // Show success message and navigate back
          if (mounted) {
            _showSuccessMessage(_getPlanName());
          }
        },
        onPaymentCancelled: () {
          // Close the dialog only, stay on subscription screen
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSuccessMessage(String planName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully subscribed to $planName!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Navigate back to profile
    Navigator.of(context).pop();
  }
}

// Payment WebView Dialog (same as booking screen)
class PaymentWebViewDialog extends StatefulWidget {
  final String paymentUrl;
  final VoidCallback onPaymentComplete;
  final VoidCallback onPaymentCancelled;

  const PaymentWebViewDialog({
    super.key,
    required this.paymentUrl,
    required this.onPaymentComplete,
    required this.onPaymentCancelled,
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
          onPageStarted: (String url) {
            print('🔗 [Subscription Payment] WebView: Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('✅ [Subscription Payment] WebView: Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
            
            // Check if payment is successful based on URL patterns
            _checkPaymentStatus(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ [Subscription Payment] WebView: Error loading page: ${error.description}');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentStatus(String url) {
    print('🔍 [Subscription Payment] Checking payment status from URL: $url');
    
    // Check for Flutterwave success indicators
    final lowerUrl = url.toLowerCase();
    
    if (lowerUrl.contains('callback') || 
        lowerUrl.contains('success') || 
        lowerUrl.contains('status=successful') ||
        lowerUrl.contains('transaction_id') ||
        lowerUrl.contains('tx_ref')) {
      
      // Check if it's actually a success (not just callback page)
      if (lowerUrl.contains('success') || 
          lowerUrl.contains('status=successful') ||
          lowerUrl.contains('transaction_id=')) {
        print('✅ [Subscription Payment] Payment successful detected!');
        
        // Wait a moment to ensure page is fully loaded
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            widget.onPaymentComplete();
          }
        });
      }
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Complete Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        // Show confirmation before closing
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Cancel Payment?'),
                            content: const Text(
                              'Are you sure you want to cancel this payment?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  widget.onPaymentCancelled();
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
              
              // WebView
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      Container(
                        color: Colors.white,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF426DC2),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading payment...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
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

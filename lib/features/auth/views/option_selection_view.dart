import 'package:flutter/material.dart';
import 'package:proplinq/features/home/views/tenant_home_view.dart';
import 'package:proplinq/features/auth/services/auth_service.dart';

class OptionSelectionView extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;

  const OptionSelectionView({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  State<OptionSelectionView> createState() => _OptionSelectionViewState();
}

class _OptionSelectionViewState extends State<OptionSelectionView> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A7CC8), // #4A7CC8
              Color(0xFF75CFEA), // #75CFEA
              Color(0xFF00EB96), // #00EB96
            ],
            stops: [0.0, 0.9999, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Hi John! text
                Text(
                  'Hi ${widget.fullName}!',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                const Text(
                  'What are we helping you with today, hotel stay or new home?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 80),
                
                // Hotel/Shortlet Option
                GestureDetector(
                  onTap: _isLoading ? null : () => _selectOption('hotel'),
                  child: Image.asset(
                    'assets/images/Frame 2147224701.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Home Option
                GestureDetector(
                  onTap: _isLoading ? null : () => _selectOption('home'),
                  child: Image.asset(
                    'assets/images/Frame 2147224703.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectOption(String option) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 User selected option: $option');
      print('🚀 Auto-login with email: ${widget.email}');
      
      // Auto-login the user with their credentials
      final response = await _authService.login(
        email: widget.email,
        password: widget.password,
      );

      if (response.success && response.data != null) {
        print('✅ Auto-login successful');
        
        // Determine initial filter based on selection
        final initialFilter = option == 'hotel' ? 'hotels' : 'non_hotels';

        // Navigate to tenant home with initial bottom sheet
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => TenantHomeView(
              initialFilter: initialFilter,
            ),
          ),
          (route) => false,
        );
      } else {
        print('❌ Auto-login failed: ${response.message}');
        // Show error and navigate to login screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-login failed. Please login manually: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Navigate back to login
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Auto-login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please login manually.'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Navigate back to login
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:proplinq/core/constants/app_typography.dart';
import '../../home/views/home_view.dart';
import '../../../core/widgets/gradient_button.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Verified Listings You Can Trust',
      subtitle: 'Every property is listed by a KYC-\nverified agent or landlord.',
      imagePath: 'assets/images/d768064b335bad732c926d8f2fe54e3c55eb343a.jpg', // Placeholder for house interior
      hasVerifiedBadge: true,
    ),
    OnboardingPage(
      title: 'Instant Virtual Tours',
      subtitle: 'Every property includes a short video\n walkthrough so you can inspect it.',
      imagePath: 'assets/images/3af693f3bf0406d67cddf98a62526eba4c273542.jpg', // Placeholder for living room
      hasPlayButton: true,
    ),
    OnboardingPage(
      title: 'Rent-now, Pay Later',
      subtitle: 'Get the home you want and pay in\n flexible installments.',
      imagePath: 'assets/images/53dcb97b346979c9bc8fb130d10122d4f378270c.png', // Placeholder for woman with keys
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeView()),
    );
  }

  void _skip() {
    _navigateToHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: index == _currentPage ? 35 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentPage 
                          ? Color.fromRGBO(66, 109, 194, 1)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Main gradient button
                  GradientButton(
                    text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    onPressed: _nextPage,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Skip or Login text
                  GestureDetector(
                    onTap: _currentPage == _pages.length - 1 ? null : _skip,
                    child: _currentPage == _pages.length - 1 
                        ? RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(
                                    color:  Color.fromRGBO(134, 134, 134, 1),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Log in',
                                  style: const TextStyle(
                                    color: Color.fromRGBO(14, 76, 221, 1),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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

  Widget _buildPage(OnboardingPage page) {
    final isFirstPage = _pages.indexOf(page) == 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image card
          Container(
            height: 408,
            width: 335,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(236, 240, 249, 1),
              borderRadius: BorderRadius.circular(37),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isFirstPage ? Stack(
              children: [
                // Inner image container for first page
                Positioned(
                  top: 23,
                  left: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 290,
                      height: 327,
                      child: Image.asset(
                        page.imagePath,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // Two horizontal lines below the image (only for first page)
                Positioned(
                  bottom: 20,
                  left: 30,
                  child: Column(
                    children: [
                      Container(
                        width: 192,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(217, 226, 243, 1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Transform.translate(
                        offset: const Offset(-47, 0),
                        child: Container(
                          width: 96,
                          height: 11,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(217, 226, 243, 1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Verified badge for first page
                if (page.hasVerifiedBadge)
                  Positioned(
                    top: 34,
                    left: 34,
                    child: Container(
                      width: 69,
                      height: 16,
                      padding: const EdgeInsets.all(3.17),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(55),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Color.fromRGBO(0, 188, 120, 1), size: 10),
                          SizedBox(width: 3.17), // gap: 3.17px
                          Text(
                            'Verified Agent',
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 7,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Checkmark for first page
                if (page.hasVerifiedBadge)
                  Positioned(
                    bottom: 20,
                    right: 27,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(229, 253, 244, 1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform.scale(
                          scale: 1, // This will make it 30% of original size
                          child: SvgPicture.asset(
                            'assets/icons/verify (1).svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ) : Stack(
              children: [
                // Image for other pages (2nd and 3rd) - centered in container
                Positioned(
                  top: 23,
                  left: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 290,
                      height: 360,
                      child: Image.asset(
                        page.imagePath,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // Play button for other pages
                if (page.hasPlayButton)
                  Positioned(
                    top: 23 + 180 - 32,
                    left: 24 + 145 - 32,
                    child: Container(
                      width: 47,
                      height: 47,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/play (1).svg',
                        height: 10,
                        width: 10,
                        fit: BoxFit.scaleDown,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: AppTypography.h3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 14),
          
          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String imagePath;
  final bool hasVerifiedBadge;
  final bool hasPlayButton;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.hasVerifiedBadge = false,
    this.hasPlayButton = false,
  });
} 
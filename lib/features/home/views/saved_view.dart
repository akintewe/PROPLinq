import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/gradient_button.dart';

class SavedView extends StatefulWidget {
  final bool isAgent;
  final VoidCallback? onExploreHome;
  
  const SavedView({super.key, this.isAgent = false, this.onExploreHome});

  @override
  State<SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<SavedView> {
  bool _isSavedProperties = true; // Toggle between Recently Viewed and Saved Properties

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
                'Saved',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tab switcher
              Center(
                child: Container(
                  width: 300,
                  height: 44,
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF0F9),
                    borderRadius: BorderRadius.circular(300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSavedProperties = false;
                            });
                          },
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: !_isSavedProperties 
                                  ? const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF426DC2),
                                        Color(0xFF63ADDC),
                                        Color(0xFF75CFEA),
                                      ],
                                      stops: [0.0, 1.0, 1.0],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(300),
                            ),
                            child: Center(
                              child: Text(
                                'Recently Viewed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: !_isSavedProperties ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSavedProperties = true;
                            });
                          },
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: _isSavedProperties 
                                  ? const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF426DC2),
                                        Color(0xFF63ADDC),
                                        Color(0xFF75CFEA),
                                      ],
                                      stops: [0.0, 1.0, 1.0],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(300),
                            ),
                            child: Center(
                              child: Text(
                                'Saved Properties',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _isSavedProperties ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Content based on selected tab
              Expanded(
                child: _isSavedProperties ? _buildSavedPropertiesContent() : _buildRecentlyViewedContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedPropertiesContent() {
    // Empty state for saved properties
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Original illustration
          SizedBox(
            width: 180,
            height: 180,
            child: Image.asset(
              'assets/icons/Frame 171.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: Color(0xFFCCCCCC),
                  ),
                );
              },
            ),
          ),
            
          // Title
          const Text(
            'No Saved Property',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Description
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start exploring listings and tap the heart icon to save your favorites. Head back to the homepage to begin.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Explore home button
          SizedBox(
            width: 250,
            child: GradientButton(
              text: 'Explore home',
              onPressed: widget.onExploreHome ?? () {
                // Fallback: try to navigate back if no callback provided
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyViewedContent() {
    // Empty state for recently viewed
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Same illustration for recently viewed
          SizedBox(
            width: 180,
            height: 180,
            child: Image.asset(
              'assets/icons/Frame 171.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.visibility_off,
                    size: 60,
                    color: Color(0xFFCCCCCC),
                  ),
                );
              },
            ),
          ),
            
          // Title
          const Text(
            'No Viewed Property',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Description
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You haven\'t viewed any listings yet. Head to the homepage to start your search.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Explore home button
          SizedBox(
            width: 250,
            child: GradientButton(
              text: 'Explore home',
              onPressed: widget.onExploreHome ?? () {
                // Fallback: try to navigate back if no callback provided
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
} 
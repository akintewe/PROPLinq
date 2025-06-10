import 'package:flutter/material.dart';

class SavedView extends StatelessWidget {
  final bool isAgent;
  
  const SavedView({super.key, this.isAgent = false});

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
              Text(
                'Saved Properties',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAgent 
                    ? 'Properties you\'ve bookmarked for clients'
                    : 'Your favorite properties and saved searches',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF868686),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Empty state for now
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 40,
                          color: Color(0xFFB0B5BB),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No saved properties yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAgent
                            ? 'Start saving properties for your clients'
                            : 'Save properties you like to view them later',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF868686),
                        ),
                        textAlign: TextAlign.center,
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
} 
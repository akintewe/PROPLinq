import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, 'Home', 'assets/icons/home_selected.svg', 'assets/icons/home_unselected.svg'),
          _buildNavItem(1, 'Saved', 'assets/icons/saved_selected.svg', 'assets/icons/saved_unselected.svg'),
          _buildNavItem(2, 'Profile', 'assets/icons/profile_selected.svg', 'assets/icons/profile_unselected.svg'),
          _buildNavItem(3, 'Settings', 'assets/icons/settings_selected.svg', 'assets/icons/settings_unselected.svg'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, String selectedIcon, String unselectedIcon) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF426DC2),  // #426DC2
                        Color(0xFF63ADDC),  // #63ADDC
                        Color(0xFF75CFEA),  // #75CFEA
                      ],
                      stops: [0.0, 1.0, 1.0],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SvgPicture.asset(
                isSelected ? selectedIcon : unselectedIcon,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isSelected ? Colors.white : const Color(0xFFB0B5BB), // rgba(176, 181, 187, 1)
                  BlendMode.srcIn,
                ),
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to Material icons if SVG fails to load
                  IconData iconData;
                  switch (title) {
                    case 'Home':
                      iconData = Icons.home;
                      break;
                    case 'Saved':
                      iconData = Icons.favorite_border;
                      break;
                    case 'Profile':
                      iconData = Icons.person_outline;
                      break;
                    case 'Settings':
                      iconData = Icons.settings_outlined;
                      break;
                    default:
                      iconData = Icons.circle;
                  }
                  return Icon(
                    iconData,
                    size: 20,
                    color: isSelected ? Colors.white : const Color(0xFFB0B5BB),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected 
                  ? const Color(0xFF426DC2)  // rgba(66, 109, 194, 1) for selected text
                  : const Color(0xFFB0B5BB),  // rgba(176, 181, 187, 1) for unselected text
            ),
          ),
        ],
      ),
    );
  }
} 
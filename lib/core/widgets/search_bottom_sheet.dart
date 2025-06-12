import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchBottomSheet extends StatefulWidget {
  final String? initialQuery;
  final Function(String)? onLocationSelected;

  const SearchBottomSheet({
    super.key,
    this.initialQuery,
    this.onLocationSelected,
  });

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _locations = [
    {
      'title': 'Near You',
      'subtitle': 'Find properties or hotels around you',
      'icon': 'assets/icons/duo-icons_location.svg',
      'iconColor': Color(0xFF426DC2),
      'isNearYou': true,
    },
    {
      'title': 'Lekki, Lagos',
      'subtitle': 'Near you',
      'icon': 'assets/icons/emojione-monotone_houses.svg',
      'iconColor': Color(0xFF63ADDC),
    },
    {
      'title': 'Ikorodu, Lagos',
      'subtitle': 'Near you',
      'icon': 'assets/icons/emojione-monotone_houses.svg',
      'iconColor': Color(0xFFE91E63),
    },
    {
      'title': 'Ikeja, Lagos',
      'subtitle': 'Near you',
      'icon': 'assets/icons/emojione-monotone_houses.svg',
      'iconColor': Color(0xFF4CAF50),
    },
    {
      'title': 'Surulere, Lagos',
      'subtitle': 'Near you',
      'icon': 'assets/icons/emojione-monotone_houses.svg',
      'iconColor': Color(0xFFFF9800),
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    // Auto-focus the search field when bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search properties or hotels',
                hintStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB0B5BB),
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xFF426DC2),
                    width: 1,
                  ),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SvgPicture.asset(
                    'assets/icons/search-normal (1).svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF868686),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                // Handle search query changes
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Location suggestions
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _locations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final location = _locations[index];
                return _buildLocationItem(location);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(Map<String, dynamic> location) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        widget.onLocationSelected?.call(location['title']);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
         
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: location['iconColor'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  location['icon'],
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    location['iconColor'],
                    BlendMode.srcIn,
                  ),
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon
                    return Icon(
                      location['isNearYou'] == true 
                          ? Icons.my_location 
                          : Icons.location_city,
                      size: 24,
                      color: location['iconColor'],
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location['subtitle'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF868686),
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

  static void show(
    BuildContext context, {
    String? initialQuery,
    Function(String)? onLocationSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchBottomSheet(
        initialQuery: initialQuery,
        onLocationSelected: onLocationSelected,
      ),
    );
  }
} 
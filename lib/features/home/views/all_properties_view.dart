import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../../auth/models/user_model.dart';
import 'property_details_view.dart';
import 'edit_property_view.dart';
import '../services/property_service.dart';

class AllPropertiesView extends StatefulWidget {
  final List<PropertyModel> properties;
  final UserModel? currentUser;

  const AllPropertiesView({
    super.key,
    required this.properties,
    this.currentUser,
  });

  @override
  State<AllPropertiesView> createState() => _AllPropertiesViewState();
}

class _AllPropertiesViewState extends State<AllPropertiesView> {
  final TextEditingController _searchController = TextEditingController();
  List<PropertyModel> _filteredProperties = [];
  String _selectedCategory = 'All';
  String _selectedType = 'All';
  bool _isGridView = true;
  
  final List<String> _categories = ['All', 'For Rent', 'For Sale', 'Hotel', 'Shortlet'];
  final List<String> _types = ['All', 'Apartment', 'House', 'Hotel', 'Land', 'Office', 'Shop'];

  @override
  void initState() {
    super.initState();
    _filteredProperties = widget.properties;
    _searchController.addListener(_filterProperties);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProperties() {
    setState(() {
      _filteredProperties = widget.properties.where((property) {
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = property.title.toLowerCase().contains(searchQuery) ||
            property.location.toLowerCase().contains(searchQuery) ||
            property.description.toLowerCase().contains(searchQuery);

        final matchesCategory = _selectedCategory == 'All' ||
            property.category.toLowerCase() == _selectedCategory.toLowerCase() ||
            (_selectedCategory == 'Hotel' && property.type.toLowerCase() == 'hotel') ||
            (_selectedCategory == 'Shortlet' && property.type.toLowerCase() == 'shortlet');

        final matchesType = _selectedType == 'All' ||
            property.type.toLowerCase() == _selectedType.toLowerCase();

        return matchesSearch && matchesCategory && matchesType;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Properties',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _filterProperties();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF426DC2) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF426DC2) : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Property Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                    });
                    _filterProperties();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF426DC2) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF426DC2) : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _selectedType = 'All';
                      });
                      _filterProperties();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF426DC2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Properties',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search properties...',
                        hintStyle: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF999999),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF426DC2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Filters
          if (_selectedCategory != 'All' || _selectedType != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Active filters: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  if (_selectedCategory != 'All')
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedCategory,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF426DC2),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = 'All';
                              });
                              _filterProperties();
                            },
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFF426DC2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_selectedType != 'All')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedType,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF426DC2),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = 'All';
                              });
                              _filterProperties();
                            },
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFF426DC2),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          if (_selectedCategory != 'All' || _selectedType != 'All')
            const SizedBox(height: 16),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredProperties.length} ${_filteredProperties.length == 1 ? 'property' : 'properties'} found',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Properties List/Grid
          Expanded(
            child: _filteredProperties.isEmpty
                ? _buildEmptyState()
                : _isGridView
                    ? _buildGridView()
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProperties.length,
      itemBuilder: (context, index) {
        return _buildGridPropertyCard(_filteredProperties[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProperties.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildListPropertyCard(_filteredProperties[index]);
      },
    );
  }

  Widget _buildGridPropertyCard(PropertyModel property) {
    return GestureDetector(
      onTap: () => _navigateToPropertyDetails(property),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: property.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(property.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: property.imageUrl == null ? Colors.grey[300] : null,
              ),
              child: Stack(
                children: [
                  if (property.imageUrl == null)
                    const Center(
                      child: Icon(
                        Icons.home_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  // Category Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        property.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // 3-dots menu
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _showPropertyOptionsMenu(context, property),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Property Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Color(0xFF999999),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF426DC2),
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

  Widget _buildListPropertyCard(PropertyModel property) {
    return GestureDetector(
      onTap: () => _navigateToPropertyDetails(property),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Property Image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                image: property.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(property.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: property.imageUrl == null ? Colors.grey[300] : null,
              ),
              child: Stack(
                children: [
                  if (property.imageUrl == null)
                    const Center(
                      child: Icon(
                        Icons.home_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  // Category Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        property.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Property Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Color(0xFF999999),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.type,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      property.price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPropertyDetails(PropertyModel property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropertyDetailsView(
          propertyData: {
            'id': property.id,
            'badges': ['Verified Agent'],
            'title': property.title,
            'location': property.location,
            'rating': '(5.0)',
            'price': property.price,
            'type': property.type,
            'category': property.category,
            'description': property.description,
            'features': property.features,
            'imageUrl': property.imageUrl,
            'images': property.images ?? (property.imageUrl != null ? [{'full_url': property.imageUrl}] : null),
            'property360_images': property.property360Images,
            'video_url': property.videoUrl,
            'user': property.user?.toJson() ?? {
              'id': widget.currentUser?.id,
              'full_name': widget.currentUser?.fullName ?? 'Agent',
              'email': widget.currentUser?.email ?? '',
              'phone_number': widget.currentUser?.phoneNumber ?? '',
              'whatsapp_number': widget.currentUser?.whatsappNumber ?? widget.currentUser?.phoneNumber ?? '',
              'profile_image_full_url': widget.currentUser?.profilePicture,
            },
            'agent': {
              'name': widget.currentUser?.fullName ?? 'Agent',
              'title': 'Agent',
              'phone': widget.currentUser?.phoneNumber ?? '',
              'email': widget.currentUser?.email ?? '',
              'whatsapp': widget.currentUser?.whatsappNumber ?? widget.currentUser?.phoneNumber ?? '',
            },
          },
          isHomeSeeker: false,
        ),
      ),
    );
  }

  void _showPropertyOptionsMenu(BuildContext context, PropertyModel property) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Property Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            
            // Edit Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF426DC2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF426DC2),
                ),
              ),
              title: const Text(
                'Edit Property',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Update property details',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF868686),
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                // Navigate to edit property screen
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditPropertyView(property: property),
                  ),
                );
                
                // If edit was successful, we should ideally refresh the property
                // For now, just show a message that the property was updated
                if (result == true && mounted) {
                  // The parent screen will handle refreshing when we return
                }
              },
            ),
            
            const SizedBox(height: 12),
            
            // Delete Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
              title: const Text(
                'Delete Property',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              subtitle: const Text(
                'Remove this property listing',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF868686),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, property);
              },
            ),
            
            const SizedBox(height: 12),
            
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF868686),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PropertyModel property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text('Are you sure you want to delete "${property.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close confirmation dialog first
              Navigator.of(context).pop();
              
              // Show loading indicator and store its context
              BuildContext? loadingDialogContext;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  loadingDialogContext = dialogContext;
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF426DC2)),
                    ),
                  );
                },
              );
              
              try {
                final propertyService = PropertyService();
                final success = await propertyService.deleteProperty(property.id);
                
                // Close loading indicator first, using the stored context
                if (loadingDialogContext != null && mounted) {
                  Navigator.of(loadingDialogContext!).pop();
                }
                
                if (mounted) {
                  if (success) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Property deleted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    // Remove property from list and update UI after closing dialog
                    setState(() {
                      widget.properties.removeWhere((p) => p.id == property.id);
                      _filterProperties();
                    });
                    
                    // If no properties left, go back to previous screen
                    if (widget.properties.isEmpty) {
                      Navigator.of(context).pop(true); // Return true to indicate refresh needed
                    }
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete property. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                // Always close loading indicator even on error
                if (loadingDialogContext != null && mounted) {
                  Navigator.of(loadingDialogContext!).pop();
                }
                
                if (mounted) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting property: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';

class EditPropertyView extends StatefulWidget {
  final PropertyModel property;

  const EditPropertyView({
    super.key,
    required this.property,
  });

  @override
  State<EditPropertyView> createState() => _EditPropertyViewState();
}

class _EditPropertyViewState extends State<EditPropertyView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  String _selectedStatus = 'available';
  bool _gated = false;
  bool _parking = false;
  List<String> _features = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property.title);
    _descriptionController = TextEditingController(text: widget.property.description);
    _priceController = TextEditingController(text: widget.property.price);
    _locationController = TextEditingController(text: widget.property.location);
    _bedroomsController = TextEditingController(text: widget.property.bedrooms?.toString() ?? '');
    _bathroomsController = TextEditingController(text: widget.property.bathrooms?.toString() ?? '');
    _features = List.from(widget.property.features ?? []);
    _selectedStatus = 'available'; // Default status since PropertyModel doesn't have this field
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
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
          'Edit Property',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Property Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Property Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter property title';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '₦ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Bedrooms and Bathrooms
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bedroomsController,
                    decoration: const InputDecoration(
                      labelText: 'Bedrooms',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bathroomsController,
                    decoration: const InputDecoration(
                      labelText: 'Bathrooms',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status Dropdown
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'available', child: Text('Available')),
                DropdownMenuItem(value: 'rented', child: Text('Rented')),
                DropdownMenuItem(value: 'sold', child: Text('Sold')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Gated Checkbox
            CheckboxListTile(
              title: const Text('Gated & Secured'),
              value: _gated,
              onChanged: (value) {
                setState(() {
                  _gated = value ?? false;
                });
              },
            ),
            
            // Parking Checkbox
            CheckboxListTile(
              title: const Text('Parking Available'),
              value: _parking,
              onChanged: (value) {
                setState(() {
                  _parking = value ?? false;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Update Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(-1.0, 0.0),
                  end: Alignment(1.0, 0.0),
                  stops: [0.0113, 0.4555, 1.1245],
                  colors: [
                    Color(0xFF426DC2),
                    Color(0xFF75CFEA),
                    Color.fromRGBO(51, 204, 153, 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ElevatedButton(
                onPressed: _updateProperty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Update Property',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProperty() async {
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF426DC2)),
            ),
          );
        },
      );

      try {
        final propertyService = PropertyService();
        
        // Parse bedrooms and bathrooms
        final bedrooms = int.tryParse(_bedroomsController.text) ?? 0;
        final bathrooms = int.tryParse(_bathroomsController.text) ?? 0;
        
        // Call the API
        final success = await propertyService.updateProperty(
          propertyId: widget.property.id,
          title: _titleController.text,
          description: _descriptionController.text,
          price: _priceController.text,
          location: _locationController.text,
          bedrooms: bedrooms,
          bathrooms: bathrooms,
          gated: _gated,
          parking: _parking,
          features: _features,
          status: _selectedStatus,
        );

        // Close loading indicator
        if (mounted) {
          Navigator.of(context).pop();
          
          if (success) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Property updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Go back to previous screen
            Navigator.of(context).pop(true); // Return true to indicate success
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update property. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Close loading indicator
        if (mounted) {
          Navigator.of(context).pop();
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating property: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}


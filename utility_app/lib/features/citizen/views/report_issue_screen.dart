import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';
import 'package:utility_app/core/i18n/translation_service.dart';


class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategory;

  final categories = ["Road", "Water", "Electricity", "Waste", "Other"];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? _pickedImage;
  bool _isLoading = false;
  double? _lat;
  double? _lng;
  String? _address;
  String _locationStatus = "Not captured";

  /// Pick image from specified source
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _detectLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _locationStatus = "Detecting...");

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationStatus = "Services disabled");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationStatus = "Permission denied");
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationStatus = "Permission permanently denied");
      return;
    } 

    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });

      // Reverse geocode to get address
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(_lat!, _lng!);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // Build address parts robustly
          List<String> parts = [];
          if (p.name != null && p.name!.isNotEmpty && p.name != p.thoroughfare) parts.add(p.name!);
          if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) parts.add(p.thoroughfare!);
          if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
          if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
          
          if (parts.isNotEmpty) {
            _address = parts.join(', ');
          } else {
            _address = "Unknown location";
          }
        }
      } catch (e) {
        print("Geocoding error: $e");
        _address = "Address unavailable";
      }

      setState(() {
        _locationStatus = "Captured: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}";
        if (_address != null) {
          _locationStatus += "\n($_address)";
        }
      });
    } catch (e) {
      setState(() => _locationStatus = "Error: $e");
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose Image Source",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Camera",
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _imageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: "Gallery",
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF057060).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF057060).withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF057060), size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  /// Encode image as base64 and return data URI
  Future<String?> _uploadImage(String reportId) async {
  if (_pickedImage == null) return null;

  try {
    File file = _pickedImage!;

    print("Encoding file: ${file.path}");
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    return "data:image/jpeg;base64,$base64Image";
  } catch (e) {
    print("Image upload failed: $e");
    return null;
  }
}

  /// Submit issue to Firestore
  void _submitIssue() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final user = _auth.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);
      
      try {
        final reportId = const Uuid().v4();

        // Upload image if selected
        String? imageUrl = await _uploadImage(reportId);

        final newReport = ReportModel(
          id: reportId,
          title: _titleController.text,
          description: _descController.text,
          category: _selectedCategory!,
          reporterName: user.email ?? '',
          reporterId: user.uid,
          imagePath: imageUrl ?? '',
          latitude: _lat,
          longitude: _lng,
          address: _address,
        );

        await _firestore
            .collection('reports')
            .doc(reportId)
            .set(newReport.toJson());
            
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('submit_success'))),
        );
        Navigator.pop(context);
      } catch (e) {
        print("Failed to save report: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('submit_fail'))),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.translate('select_category'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
          // Elegant Header
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF057060),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(context.translate('report_issue'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF057060), Color(0xFF00BFA5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate('issue_details'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    Text(
                      context.translate('issue_details_subtitle'),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Title Field
                    _buildInputField(
                      controller: _titleController,
                      label: context.translate('title'),
                      hint: context.translate('title_hint'),
                      icon: Icons.title,
                      validator: (val) => val == null || val.isEmpty ? context.translate('field_required') : null,
                    ),
                    const SizedBox(height: 20),

                    // Category Field
                    _buildDropdownField(),
                    const SizedBox(height: 20),

                    // Description Field
                    _buildInputField(
                      controller: _descController,
                      label: context.translate('description'),
                      hint: context.translate('description_hint'),
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (val) => val == null || val.isEmpty ? context.translate('field_required') : null,
                    ),
                    const SizedBox(height: 24),

                    // Image Picker Section
                    Text(
                      context.translate('attachment'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImagePicker(),
                    const SizedBox(height: 24),

                    // Location Section
                    Text(
                      context.translate('location'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLocationPicker(),
                    const SizedBox(height: 40),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitIssue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF057060),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF057060).withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.translate('submit_report'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFF057060), size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(context.translate('category'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF057060), size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            hint: Text(context.translate('select_category'), style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val),
            validator: (val) => val == null ? "Please select a category" : null,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          image: _pickedImage != null
              ? DecorationImage(image: FileImage(_pickedImage!), fit: BoxFit.cover)
              : null,
        ),
        child: _pickedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    context.translate('snap_photo'),
                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    context.translate('help_authorities'),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Color(0xFF057060), size: 20),
                ),
              ),
      ),
    );
  }
  Widget _buildLocationPicker() {
    final hasLocation = _lat != null && _lng != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (hasLocation ? Colors.green : Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasLocation ? Icons.location_on : Icons.location_off,
              color: hasLocation ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLocation ? context.translate('captured') : context.translate('location'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _locationStatus,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _detectLocation,
            icon: const Icon(Icons.my_location, size: 18),
            label: Text(hasLocation ? "Retake" : context.translate('detect_location')),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF057060)),
          ),
        ],
      ),
    );
  }
}


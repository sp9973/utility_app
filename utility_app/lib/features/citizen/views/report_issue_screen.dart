import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../citizen/models/report_model.dart';

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

  /// Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      print("Picked image path: ${_pickedImage!.path}");
    } else {
      print("No image selected");
    }
  }

  /// Upload image to Firebase Storage and return URL
  Future<String?> _uploadImage(String reportId) async {
    if (_pickedImage == null) return null;

    try {
      final ref = FirebaseStorage.instance.ref('report_images/$reportId.jpg');
      final uploadTask = ref.putFile(_pickedImage!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print("Uploaded image URL: $downloadUrl");
      return downloadUrl;
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
      );

      try {
        await _firestore
            .collection('reports')
            .doc(reportId)
            .set(newReport.toJson());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Issue reported successfully!")),
        );
        Navigator.pop(context);
      } catch (e) {
        print("Failed to save report: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to submit issue")));
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a category")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Report an Issue"),
        backgroundColor: const Color(0xFF057060),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? "Enter issue title"
                                : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Category",
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedCategory,
                    items:
                        categories
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    validator:
                        (val) =>
                            val == null ? "Please select a category" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? "Enter description"
                                : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text(
                          "Upload Image",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF057060),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _pickedImage != null
                          ? Image.file(
                            _pickedImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                          : const Text("No image selected"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text(
                        "Submit Issue",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: _submitIssue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF057060),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

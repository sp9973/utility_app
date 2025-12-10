import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  String id;
  String title;
  String description;
  String category;
  String imagePath;
  String status;
  DateTime createdAt;
  String reporterName;
  String reporterId;
  double? latitude;
  double? longitude;

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imagePath = '',
    this.status = 'Pending',
    DateTime? createdAt,
    this.reporterName = '',
    this.reporterId = '',
    this.latitude,
    this.longitude,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'imagePath': imagePath,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt), 
        'reporterName': reporterName,
        'reporterId': reporterId,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        imagePath: json['imagePath'] as String? ?? '',
        status: json['status'] as String? ?? 'Pending',
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        reporterName: json['reporterName'] as String? ?? '',
        reporterId: json['reporterId'] as String? ?? '',
        latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
        longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      );
}

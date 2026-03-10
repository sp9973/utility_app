import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF057060);
  static const primaryLight = Color(0xFF00BFA5);
  static const adminBlue = Color(0xFF0072FF);
  static const authorityDark = Color(0xFF0A4D68);
  static const background = Color(0xFFF5F5F5);
}

class AppCollections {
  static const reports = 'reports';
  static const users = 'users';
}

class ReportStatus {
  static const pending = 'Pending';
  static const inProgress = 'In Progress';
  static const resolved = 'Resolved';
  static const rejected = 'Rejected';

  static const all = [pending, inProgress, resolved, rejected];
}

class IssueCategory {
  static const all = ['Road', 'Water', 'Electricity', 'Waste', 'Other'];
}

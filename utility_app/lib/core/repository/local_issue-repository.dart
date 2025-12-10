import 'dart:async';
import 'package:uuid/uuid.dart';
import 'issue_repository.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';

// Simple in-memory repository. You can persist to shared_preferences or local DB later.
class LocalIssueRepository implements IssueRepository {
  final List<ReportModel> _issues = [];
  final _uuid = const Uuid();

  LocalIssueRepository() {
    // Optionally seed with demo data for presentation
    _issues.addAll([
      ReportModel(
        id: _uuid.v4(),
        title: 'Streetlight not working',
        description: 'Streetlight near market is off since 3 days.',
        category: 'Electricity',
        status: 'Pending',
      ),
      ReportModel(
        id: _uuid.v4(),
        title: 'Garbage overflow',
        description: 'Garbage pile near bus stop.',
        category: 'Sanitation',
        status: 'In Progress',
      ),
    ]);
  }

  @override
  Future<void> addIssue(ReportModel issue) async {
    // ensure id
    if (issue.id.isEmpty) issue.id = _uuid.v4();
    _issues.insert(0, issue);
    // If you want persistence: write to file / shared_preferences here
    await Future.delayed(const Duration(milliseconds: 150)); // simulate latency
  }

  @override
  Future<void> deleteIssue(String id) async {
    _issues.removeWhere((e) => e.id == id);
  }

  @override
  Future<ReportModel> getIssueById(String id) async {
    return _issues.firstWhere((e) => e.id == id);
  }

  @override
  Future<List<ReportModel>> getIssues() async {
    await Future.delayed(const Duration(milliseconds: 150)); // simulate latency
    return List.from(_issues);
  }

  @override
  Future<void> updateIssue(ReportModel issue) async {
    final idx = _issues.indexWhere((e) => e.id == issue.id);
    if (idx != -1) _issues[idx] = issue;
  }
}

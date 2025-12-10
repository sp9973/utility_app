import 'package:utility_app/features/citizen/models/report_model.dart';

abstract class IssueRepository {
  Future<List<ReportModel>> getIssues();
  Future<ReportModel> getIssueById(String id);
  Future<void> addIssue(ReportModel issue);
  Future<void> updateIssue(ReportModel issue);
  Future<void> deleteIssue(String id);
}

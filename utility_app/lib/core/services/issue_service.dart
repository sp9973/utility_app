import 'package:utility_app/core/repository/local_issue-repository.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';
import 'package:utility_app/core/repository/issue_repository.dart';

class IssueService {
  IssueService._privateConstructor();
  static final IssueService instance = IssueService._privateConstructor();

  // Change this to RemoteIssueRepository() to use network backend later.
  final IssueRepository _repo = LocalIssueRepository();
  // final IssueRepository _repo = RemoteIssueRepository(); // swap here

  Future<List<ReportModel>> getIssues() => _repo.getIssues();
  Future<void> addIssue(ReportModel issue) => _repo.addIssue(issue);
  Future<void> updateIssue(ReportModel issue) => _repo.updateIssue(issue);
  Future<ReportModel> getIssueById(String id) => _repo.getIssueById(id);
  Future<void> deleteIssue(String id) => _repo.deleteIssue(id);
}

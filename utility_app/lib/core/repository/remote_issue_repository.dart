import 'issue_repository.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';

// This implementation will call your REST API or Firebase later.
// For now it returns mock responses so UI code doesn't change.
class RemoteIssueRepository implements IssueRepository {
  // TODO: inject ApiServices (api_services.dart) to call real backend.
  @override
  Future<void> addIssue(ReportModel issue) async {
    // call your API here; for demo we'll simulate delay
    await Future.delayed(const Duration(milliseconds: 300));
    // throw UnimplementedError(); // later implement
  }

  @override
  Future<void> deleteIssue(String id) async {
    await Future.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<ReportModel> getIssueById(String id) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return ReportModel(
      id: id,
      title: 'Remote sample',
      description: 'Sample',
      category: 'Sample',
    );
  }

  @override
  Future<List<ReportModel>> getIssues() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // return empty list or sample data
    return [];
  }

  @override
  Future<void> updateIssue(ReportModel issue) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

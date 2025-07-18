import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:phcl_accounts/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardData {
  final DashboardRepository repository;

  GetDashboardData(this.repository);

  Future<DashboardData> call({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await repository.getDashboardData(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
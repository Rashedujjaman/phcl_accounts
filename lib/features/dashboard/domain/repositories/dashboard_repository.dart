import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';

abstract class DashboardRepository {
  Future<DashboardData> getDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  });
}
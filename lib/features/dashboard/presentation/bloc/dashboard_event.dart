part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;

  const DashboardEvent({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class LoadDashboardData extends DashboardEvent {
  const LoadDashboardData({super.startDate, super.endDate});
}

class RefreshDashboardData extends DashboardEvent {
  const RefreshDashboardData({super.startDate, super.endDate});
}
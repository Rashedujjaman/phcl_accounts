part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadDashboardData({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class RestoreDashboardState extends DashboardEvent {
  final DashboardState state;

  const RestoreDashboardState(this.state);

  @override
  List<Object?> get props => [state];
}
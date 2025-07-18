part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial() : super();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading() : super();
}

class DashboardLoaded extends DashboardState {
  final DashboardData dashboardData;
  
  const DashboardLoaded(this.dashboardData);

  @override
  List<Object?> get props => [dashboardData];
}

class DashboardRefreshing extends DashboardLoaded {
  const DashboardRefreshing(super.dashboardData);
}

class DashboardError extends DashboardState {
  final String message;
  
  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
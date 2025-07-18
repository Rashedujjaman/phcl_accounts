import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:phcl_accounts/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardData getDashboardData;
  DashboardData? _cachedData;

  DashboardBloc({required this.getDashboardData}) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      // Only show loading if we don't have cached data
      if (_cachedData == null) {
        emit(DashboardLoading());
      }

      final dashboardData = await getDashboardData(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      _cachedData = dashboardData;
      emit(DashboardLoaded(dashboardData));
    } catch (e) {
      // If we have cached data, show it with error
      if (_cachedData != null) {
        emit(DashboardLoaded(_cachedData!));
      } else {
        emit(DashboardError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      emit(DashboardRefreshing((state as DashboardLoaded).dashboardData));
    }
    
    try {
      final dashboardData = await getDashboardData(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      _cachedData = dashboardData;
      emit(DashboardLoaded(dashboardData));
    } catch (e) {
      if (_cachedData != null) {
        emit(DashboardLoaded(_cachedData!));
      } else {
        emit(DashboardError(e.toString()));
      }
    }
  }
}
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:phcl_accounts/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardData getDashboardData;

  DashboardBloc({required this.getDashboardData}) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final dashboardData = await getDashboardData(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(DashboardLoaded(dashboardData));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
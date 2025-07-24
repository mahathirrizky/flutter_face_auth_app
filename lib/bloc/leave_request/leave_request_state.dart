part of 'leave_request_bloc.dart';

@immutable
sealed class LeaveRequestState {}

final class LeaveRequestInitial extends LeaveRequestState {}

final class LeaveRequestLoading extends LeaveRequestState {}

final class LeaveRequestsLoadedSuccess extends LeaveRequestState {
  final List<LeaveRequest> leaveRequests;

  LeaveRequestsLoadedSuccess({required this.leaveRequests});
}

final class LeaveRequestAppliedSuccess extends LeaveRequestState {}

final class LeaveRequestCancelledSuccess extends LeaveRequestState {}

final class LeaveRequestFailure extends LeaveRequestState {
  final String error;

  LeaveRequestFailure({required this.error});
}




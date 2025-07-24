part of 'leave_request_bloc.dart';

@immutable
sealed class LeaveRequestEvent {}

class FetchMyLeaveRequests extends LeaveRequestEvent {
  final String? startDate;
  final String? endDate;

  FetchMyLeaveRequests({this.startDate, this.endDate});
}



class ApplyLeaveRequested extends LeaveRequestEvent {
  final String type;
  final String startDate;
  final String endDate;
  final String reason;
  final File? sickNoteFile;

  ApplyLeaveRequested({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.sickNoteFile,
  });
}

class CancelLeaveRequestRequested extends LeaveRequestEvent {
  final int requestId;

  CancelLeaveRequestRequested({required this.requestId});
}


import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_face_auth_app/repositories/leave_request_repository.dart';
import 'package:meta/meta.dart';

part 'leave_request_event.dart';
part 'leave_request_state.dart';

class LeaveRequestBloc extends Bloc<LeaveRequestEvent, LeaveRequestState> {
  final LeaveRequestRepository _leaveRequestRepository;

  LeaveRequestBloc({required LeaveRequestRepository leaveRequestRepository})
      : _leaveRequestRepository = leaveRequestRepository,
        super(LeaveRequestInitial()) {
    on<FetchMyLeaveRequests>(_onFetchMyLeaveRequests);
    on<ApplyLeaveRequested>(_onApplyLeaveRequested);
    on<CancelLeaveRequestRequested>(_onCancelLeaveRequestRequested);
  }

  Future<void> _onFetchMyLeaveRequests(
    FetchMyLeaveRequests event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(LeaveRequestLoading());
    try {
      final leaveRequests = await _leaveRequestRepository.getMyLeaveRequests(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(LeaveRequestsLoadedSuccess(leaveRequests: leaveRequests));
    } catch (e) {
      emit(LeaveRequestFailure(error: e.toString()));
    }
  }

  Future<void> _onApplyLeaveRequested(
    ApplyLeaveRequested event,
    Emitter<LeaveRequestState> emit,
  ) async {
    // Keep the current state to avoid losing the list view while applying
    final currentState = state;
    emit(LeaveRequestLoading()); // Show a general loading state
    try {
      await _leaveRequestRepository.applyLeave(
        type: event.type,
        startDate: event.startDate,
        endDate: event.endDate,
        reason: event.reason,
        sickNoteFile: event.sickNoteFile,
      );
      emit(LeaveRequestAppliedSuccess());
      // Refresh the list after applying for leave
      add(FetchMyLeaveRequests());
    } catch (e) {
      emit(LeaveRequestFailure(error: e.toString()));
      // If the previous state was loaded, restore it so the list doesn't disappear on error.
      if (currentState is LeaveRequestsLoadedSuccess) {
        emit(currentState);
      }
    }
  }

  Future<void> _onCancelLeaveRequestRequested(
    CancelLeaveRequestRequested event,
    Emitter<LeaveRequestState> emit,
  ) async {
    final currentState = state;
    emit(LeaveRequestLoading());
    try {
      await _leaveRequestRepository.cancelLeaveRequest(event.requestId);
      emit(LeaveRequestCancelledSuccess());
      add(FetchMyLeaveRequests()); // Refresh the list after cancellation
    } catch (e) {
      emit(LeaveRequestFailure(error: e.toString()));
      if (currentState is LeaveRequestsLoadedSuccess) {
        emit(currentState);
      }
    }
  }
}

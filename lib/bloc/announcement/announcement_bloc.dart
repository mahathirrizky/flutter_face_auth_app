import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter_face_auth_app/repositories/announcement_repository.dart';

part 'announcement_event.dart';
part 'announcement_state.dart';

class AnnouncementBloc extends Bloc<AnnouncementEvent, AnnouncementState> {
  final AnnouncementRepository _announcementRepository;

  AnnouncementBloc({required AnnouncementRepository announcementRepository})
      : _announcementRepository = announcementRepository,
        super(AnnouncementInitial()) {
    on<FetchAnnouncements>(_onFetchAnnouncements);
    on<ReceiveNewAnnouncement>(_onReceiveNewAnnouncement);
    on<MarkAnnouncementAsRead>(_onMarkAnnouncementAsRead);
  }

  Future<void> _onFetchAnnouncements(
    FetchAnnouncements event,
    Emitter<AnnouncementState> emit,
  ) async {
    emit(AnnouncementLoading());
    try {
      final announcements = await _announcementRepository.getAnnouncements();
      print('DEBUG: Announcements from backend: $announcements');
      emit(AnnouncementLoaded(announcements: announcements));
    } catch (e) {
      emit(AnnouncementError(message: 'Failed to fetch announcements: $e'));
    }
  }

  void _onReceiveNewAnnouncement(
    ReceiveNewAnnouncement event,
    Emitter<AnnouncementState> emit,
  ) {
    if (state is AnnouncementLoaded) {
      final currentState = state as AnnouncementLoaded;
      final updatedAnnouncements = List<Announcement>.from(currentState.announcements);
      // Check if the announcement already exists to prevent duplicates
      if (!updatedAnnouncements.any((ann) => ann.id == event.announcement.id)) {
        updatedAnnouncements.insert(0, event.announcement.copyWith(isRead: false));
      }
      emit(AnnouncementLoaded(announcements: updatedAnnouncements));
    } else {
      emit(AnnouncementLoaded(announcements: [event.announcement.copyWith(isRead: false)]));
    }
  }

  Future<void> _onMarkAnnouncementAsRead(
    MarkAnnouncementAsRead event,
    Emitter<AnnouncementState> emit,
  ) async {
    if (state is AnnouncementLoaded) {
      final currentState = state as AnnouncementLoaded;
      try {
        await _announcementRepository.markAsRead(event.messageId);
        final updatedAnnouncements = currentState.announcements.map((ann) {
          if (ann.id == event.messageId) {
            return ann.copyWith(isRead: true);
          }
          return ann;
        }).toList();
        emit(AnnouncementLoaded(announcements: updatedAnnouncements));
      } catch (e) {
        // Optionally, handle the error, e.g., by emitting an error state
        emit(AnnouncementError(message: 'Failed to mark as read: $e'));
      }
    }
  }
}

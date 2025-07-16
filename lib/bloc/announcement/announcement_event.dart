part of 'announcement_bloc.dart';

@immutable
sealed class AnnouncementEvent {}

class FetchAnnouncements extends AnnouncementEvent {}

class ReceiveNewAnnouncement extends AnnouncementEvent {
  final Announcement announcement;

  ReceiveNewAnnouncement({required this.announcement});
}

class MarkAnnouncementAsRead extends AnnouncementEvent {
  final int messageId;

  MarkAnnouncementAsRead({required this.messageId});
}

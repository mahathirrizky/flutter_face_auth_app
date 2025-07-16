part of 'announcement_bloc.dart';

@immutable
sealed class AnnouncementState {}

final class AnnouncementInitial extends AnnouncementState {}

final class AnnouncementLoading extends AnnouncementState {}

final class AnnouncementLoaded extends AnnouncementState {
  final List<Announcement> announcements;

  AnnouncementLoaded({required this.announcements});
}

final class AnnouncementError extends AnnouncementState {
  final String message;

  AnnouncementError({required this.message});
}

class Announcement {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? expireDate;
  final bool isRead;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.expireDate,
    this.isRead = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      expireDate: json['expire_date'] != null ? DateTime.parse(json['expire_date']) : null,
      isRead: json['is_read'] ?? false,
    );
  }

  Announcement copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? expireDate,
    bool? isRead,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      expireDate: expireDate ?? this.expireDate,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'Announcement(id: $id, title: $title, content: $content, createdAt: $createdAt, expireDate: $expireDate, isRead: $isRead)';
  }
}

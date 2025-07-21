import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/bloc/bloc.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AnnouncementCard extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementCard({super.key, required this.announcement});

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _isContentExpanded = false;

  void _toggleContentExpanded() {
    setState(() {
      _isContentExpanded = !_isContentExpanded;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMMM yyyy, HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final announcement = widget.announcement;
    
    final cardColor = announcement.isRead ? AppColors.bgMuted : AppColors.bgMuted.withAlpha(230);
    final textColor = AppColors.textBase;
    final fontWeight = announcement.isRead ? FontWeight.normal : FontWeight.bold;
    final borderSide = announcement.isRead ? BorderSide.none : BorderSide(color: AppColors.secondary, width: 2.0);

    return GestureDetector(
      onTap: () {
        if (!announcement.isRead) {
          context.read<AnnouncementBloc>().add(MarkAnnouncementAsRead(messageId: announcement.id));
        }
        _toggleContentExpanded(); // Toggle content expansion on tap
      },
      child: Card(
        color: cardColor,
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: borderSide,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!announcement.isRead)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      announcement.title, // Use actual title from model
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: fontWeight,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Diterbitkan pada: ${_formatDate(announcement.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                'Berlaku hingga: ${announcement.expireDate != null ? _formatDate(announcement.expireDate) : 'Tidak ada tanggal kedaluwarsa'}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedCrossFade(
                firstChild: Text(
                  announcement.content,
                  style: TextStyle(color: textColor, fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                secondChild: Text(
                  announcement.content,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
                crossFadeState: _isContentExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
              if (announcement.content.length > 100) // Only show button if content is long
                TextButton(
                  onPressed: _toggleContentExpanded,
                  child: Text(
                    _isContentExpanded ? 'Tampilkan Lebih Sedikit' : 'Baca Selengkapnya',
                    style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

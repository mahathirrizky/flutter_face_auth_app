import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:flutter_face_auth_app/bloc/bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart'; // Import intl package

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  final Map<int, bool> _expandedMessages = {}; // To track expanded messages

  @override
  void initState() {
    super.initState();
    // Only fetch announcements if they haven't been loaded yet.
    // This prevents overwriting the state updated by WebSocket messages.
    if (context.read<AnnouncementBloc>().state is! AnnouncementLoaded) {
      context.read<AnnouncementBloc>().add(FetchAnnouncements());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showToast(BuildContext context, String message, {ToastificationType type = ToastificationType.info}) {
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topRight,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMMM yyyy, HH:mm').format(date.toLocal());
  }

  void _toggleExpanded(int messageId) {
    setState(() {
      _expandedMessages[messageId] = !(_expandedMessages[messageId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman'),
        backgroundColor: AppColors.bgMuted,
        foregroundColor: AppColors.textBase,
        toolbarHeight: 45.0,
        elevation: 0.0,
        shadowColor: Colors.transparent,
      ),
      body: BlocConsumer<AnnouncementBloc, AnnouncementState>(
        listener: (context, state) {
          if (state is AnnouncementError) {
            if (!mounted) return; // Check mounted before using context
            _showToast(context, state.message, type: ToastificationType.error);
          }
        },
        builder: (context, state) {
          if (state is AnnouncementLoading) {
            return Center(child: CircularProgressIndicator(color: AppColors.secondary));
          } else if (state is AnnouncementLoaded) {
            final announcements = state.announcements;
            
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (announcements.isEmpty)
                      Card(
                        color: AppColors.bgMuted,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Tidak ada pengumuman terbaru.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = announcements[index];
                          final isExpanded = _expandedMessages[announcement.id] ?? false;
                          
                          // Styling for unread messages
                          final cardColor = announcement.isRead ? AppColors.bgMuted : AppColors.bgMuted.withAlpha(230);
                          final textColor = AppColors.textBase;
                          final fontWeight = announcement.isRead ? FontWeight.normal : FontWeight.bold;
                          final borderSide = announcement.isRead ? BorderSide.none : BorderSide(color: AppColors.secondary, width: 2.0);

                          return GestureDetector(
                            onTap: () {
                              if (!announcement.isRead) {
                                context.read<AnnouncementBloc>().add(MarkAnnouncementAsRead(messageId: announcement.id));
                              }
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
                                            'Pengumuman Baru',
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
                                    Text(
                                      announcement.content,
                                      style: TextStyle(color: textColor, fontSize: 14),
                                      maxLines: isExpanded ? null : 3,
                                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                    ),
                                    if (announcement.content.length > 100)
                                      TextButton(
                                        onPressed: () => _toggleExpanded(announcement.id),
                                        child: Text(
                                          isExpanded ? 'Tampilkan Lebih Sedikit' : 'Baca Selengkapnya',
                                          style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          } else if (state is AnnouncementInitial) {
            return const Center(child: Text('Loading announcements...'));
          } else {
            return const Center(child: Text('No announcements available.'));
          }
        },
      ),
    );
  }
}
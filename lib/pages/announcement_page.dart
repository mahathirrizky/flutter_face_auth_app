import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:flutter_face_auth_app/bloc/bloc.dart';
import 'package:flutter_face_auth_app/widgets/announcement_card.dart';
import 'package:toastification/toastification.dart';


class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}



class _AnnouncementPageState extends State<AnnouncementPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (context.read<AnnouncementBloc>().state is! AnnouncementLoaded) {
      context.read<AnnouncementBloc>().add(FetchAnnouncements());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AnnouncementBloc>().add(FetchAnnouncements());
    }
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
            if (!mounted) return;
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
                          return AnnouncementCard(announcement: announcement); // Use the new widget
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
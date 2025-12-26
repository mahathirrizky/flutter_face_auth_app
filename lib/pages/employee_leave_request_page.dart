import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/bloc/bloc.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:toastification/toastification.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'dart:io'; // Import for File
import 'package:loading_animation_widget/loading_animation_widget.dart';

class EmployeeLeaveRequestPage extends StatefulWidget {
  const EmployeeLeaveRequestPage({super.key});

  @override
  State<EmployeeLeaveRequestPage> createState() => _EmployeeLeaveRequestPageState();
}

class _EmployeeLeaveRequestPageState extends State<EmployeeLeaveRequestPage> {
  String? _leaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  File? _sickNoteFile; // Added for sick note file

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  final TextEditingController _filterStartDateController = TextEditingController();
  final TextEditingController _filterEndDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default filter dates to last 30 days
    _filterEndDate = DateTime.now();
    _filterStartDate = _filterEndDate!.subtract(const Duration(days: 30));

    _filterStartDateController.text = _formatDateDisplay(_filterStartDate);
    _filterEndDateController.text = _formatDateDisplay(_filterEndDate);

    // Fetch leave requests for the default range when the page initializes
    context.read<LeaveRequestBloc>().add(FetchMyLeaveRequests(
          startDate: _filterStartDate?.toIso8601String().split('T')[0],
          endDate: _filterEndDate?.toIso8601String().split('T')[0],
        ));
  }

  void _showToast(String message, {ToastificationType type = ToastificationType.info}) {
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
    );
  }

  void _showApplyLeaveDialog(BuildContext parentContext) {
    String? dialogLeaveType = _leaveType;
    DateTime? dialogStartDate = _startDate;
    DateTime? dialogEndDate = _endDate;
    final TextEditingController dialogReasonController = TextEditingController(text: _reasonController.text);
    File? dialogSickNoteFile = _sickNoteFile; // Pass current file to dialog

    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.bgMuted,
          title: Text(
            'Ajukan Cuti Baru',
            style: TextStyle(color: AppColors.textBase),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: dialogLeaveType,
                      decoration: InputDecoration(
                        labelText: 'Jenis Cuti',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.textMuted),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.secondary),
                        ),
                      ),
                      dropdownColor: AppColors.bgMuted,
                      style: TextStyle(color: AppColors.textBase),
                      items: const [
                        DropdownMenuItem(value: 'cuti', child: Text('Cuti Tahunan')),
                        DropdownMenuItem(value: 'sakit', child: Text('Cuti Sakit')),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          dialogLeaveType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: _formatDateDisplay(dialogStartDate)),
                      decoration: InputDecoration(
                        labelText: 'Tanggal Mulai',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.textMuted),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.secondary),
                        ),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppColors.secondary,
                                  onPrimary: AppColors.textBase,
                                  onSurface: AppColors.textBase,
                                  surface: AppColors.bgMuted,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.secondary,
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            dialogStartDate = picked;
                          });
                        }
                      },
                      style: TextStyle(color: AppColors.textBase),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: _formatDateDisplay(dialogEndDate)),
                      decoration: InputDecoration(
                        labelText: 'Tanggal Berakhir',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.textMuted),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.secondary),
                        ),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppColors.secondary,
                                  onPrimary: AppColors.textBase,
                                  onSurface: AppColors.textBase,
                                  surface: AppColors.bgMuted,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.secondary,
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            dialogEndDate = picked;
                          });
                        }
                      },
                      style: TextStyle(color: AppColors.textBase),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dialogReasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Alasan',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.textMuted),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.secondary),
                        ),
                      ),
                      style: TextStyle(color: AppColors.textBase),
                    ),
                    if (dialogLeaveType == 'sakit') ...[
                      const SizedBox(height: 16),
                      Text(
                        dialogSickNoteFile != null
                            ? 'File Terpilih: ${dialogSickNoteFile!.path.split('/').last}'
                            : 'Belum ada surat sakit dipilih',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                          );
                          if (result != null) {
                            setState(() {
                              dialogSickNoteFile = File(result.files.single.path!);
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.textBase,
                        ),
                        child: const Text('Pilih Surat Sakit'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogLeaveType == null || dialogStartDate == null || dialogEndDate == null || dialogReasonController.text.isEmpty) {
                  _showToast('Harap isi semua kolom.', type: ToastificationType.error);
                  return;
                }
                if (dialogLeaveType == 'sakit' && dialogSickNoteFile == null) {
                  _showToast('Harap unggah surat sakit untuk cuti sakit.', type: ToastificationType.error);
                  return;
                }
                parentContext.read<LeaveRequestBloc>().add(
                      ApplyLeaveRequested(
                        type: dialogLeaveType!,
                        startDate: dialogStartDate!.toIso8601String().split('T')[0],
                        endDate: dialogEndDate!.toIso8601String().split('T')[0],
                        reason: dialogReasonController.text,
                        sickNoteFile: dialogSickNoteFile, // Pass the file
                      ),
                    );
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textBase,
              ),
              child: const Text('Ajukan Cuti'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateDisplay(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Cuti'),
        backgroundColor: AppColors.bgMuted,
        foregroundColor: AppColors.textBase,
        toolbarHeight: 45.0,
        elevation: 0.0,
        shadowColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showApplyLeaveDialog(context),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: AppColors.textBase),
      ),
      body: BlocListener<LeaveRequestBloc, LeaveRequestState>(
        listener: (context, state) {
          if (state is LeaveRequestLoading) {
            _showToast('Memproses permintaan...', type: ToastificationType.info);
          } else if (state is LeaveRequestAppliedSuccess) {
            _showToast('Pengajuan cuti berhasil!', type: ToastificationType.success);
            // Clear form fields after successful submission
            setState(() {
              _leaveType = null;
              _startDate = null;
              _endDate = null;
              _reasonController.clear();
            });
            // Refresh the list of leave requests
            context.read<LeaveRequestBloc>().add(FetchMyLeaveRequests());
          } else if (state is LeaveRequestFailure) {
            _showToast('Error: ${state.error}', type: ToastificationType.error);
          } else if (state is LeaveRequestsLoadedSuccess) {
            _showToast('Riwayat cuti berhasil dimuat.', type: ToastificationType.success);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [


                Card(
                  color: AppColors.bgMuted,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Riwayat Cuti',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBase,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          readOnly: true,
                          controller: _filterStartDateController,
                          decoration: InputDecoration(
                            labelText: 'Dari Tanggal',
                            labelStyle: TextStyle(color: AppColors.textMuted),
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.textMuted),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.secondary),
                            ),
                          ),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _filterStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: AppColors.secondary,
                                      onPrimary: AppColors.textBase,
                                      onSurface: AppColors.textBase,
                                      surface: AppColors.bgMuted,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _filterStartDate = picked;
                                _filterStartDateController.text = _formatDateDisplay(picked);
                                // Trigger fetch with new filter
                                context.read<LeaveRequestBloc>().add(FetchMyLeaveRequests(
                                      startDate: _filterStartDate?.toIso8601String().split('T')[0],
                                      endDate: _filterEndDate?.toIso8601String().split('T')[0],
                                    ));
                              });
                            }
                          },
                          style: TextStyle(color: AppColors.textBase),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          readOnly: true,
                          controller: _filterEndDateController,
                          decoration: InputDecoration(
                            labelText: 'Sampai Tanggal',
                            labelStyle: TextStyle(color: AppColors.textMuted),
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.textMuted),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.secondary),
                            ),
                          ),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _filterEndDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: AppColors.secondary,
                                      onPrimary: AppColors.textBase,
                                      onSurface: AppColors.textBase,
                                      surface: AppColors.bgMuted,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _filterEndDate = picked;
                                _filterEndDateController.text = _formatDateDisplay(picked);
                                // Trigger fetch with new filter
                                context.read<LeaveRequestBloc>().add(FetchMyLeaveRequests(
                                      startDate: _filterStartDate?.toIso8601String().split('T')[0],
                                      endDate: _filterEndDate?.toIso8601String().split('T')[0],
                                    ));
                              });
                            }
                          },
                          style: TextStyle(color: AppColors.textBase),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Riwayat Pengajuan Cuti Card
                Card(
                  color: AppColors.bgMuted,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Pengajuan Cuti',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBase,
                          ),
                        ),
                        const SizedBox(height: 8),
                        BlocBuilder<LeaveRequestBloc, LeaveRequestState>(
                          builder: (context, state) {
                            if (state is LeaveRequestLoading) {
                              return Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: AppColors.secondary,
                                  size: 50,
                                ),
                              );
                            } else if (state is LeaveRequestsLoadedSuccess) {
                              if (state.leaveRequests.isNotEmpty) {
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.leaveRequests.length,
                                  itemBuilder: (context, index) {
                                    final request = state.leaveRequests[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${request.type} (${_formatDateDisplay(request.startDate)} - ${_formatDateDisplay(request.endDate)})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textBase,
                                            ),
                                          ),
                                          Text(
                                            'Alasan: ${request.reason}',
                                            style: TextStyle(color: AppColors.textMuted),
                                          ),
                                          Row(
                                            children: [
                                              Text('Status: ', style: TextStyle(color: AppColors.textMuted)),
                                              Text(
                                                request.status,
                                                style: TextStyle(color: _getStatusColor(request.status)),
                                              ),
                                              if (request.status == 'pending') ...[
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext dialogContext) {
                                                        return AlertDialog(
                                                          title: const Text('Batalkan Pengajuan Cuti'),
                                                          content: const Text('Apakah Anda yakin ingin membatalkan pengajuan cuti ini?'),
                                                          actions: <Widget>[
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(dialogContext).pop();
                                                              },
                                                              child: const Text('Tidak'),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                Navigator.of(dialogContext).pop();
                                                                context.read<LeaveRequestBloc>().add(
                                                                      CancelLeaveRequestRequested(requestId: request.id),
                                                                    );
                                                              },
                                                              child: const Text('Ya'),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.danger,
                                                    foregroundColor: AppColors.textBase,
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    minimumSize: Size.zero, // Remove fixed size
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrink wrap for smaller button
                                                  ),
                                                  child: const Text('Batalkan'),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (index < state.leaveRequests.length - 1)
                                            const Divider(color: AppColors.textMuted), // Separator
                                        ],
                                      ),
                                    );
                                  },
                                );
                              } else {
                                return Text(
                                  'Tidak ada riwayat pengajuan cuti.',
                                  style: TextStyle(color: AppColors.textMuted),
                                );
                              }
                            } else if (state is LeaveRequestFailure) {
                              return Text(
                                'Gagal memuat riwayat cuti: ${state.error}',
                                style: TextStyle(color: Colors.red),
                              );
                            } else if (state is LeaveRequestCancelledSuccess) {
                              _showToast('Pengajuan cuti berhasil dibatalkan!', type: ToastificationType.success);
                              context.read<LeaveRequestBloc>().add(FetchMyLeaveRequests()); // Refresh the list
                            }
                            return Text(
                              'Tidak ada riwayat pengajuan cuti.',
                              style: TextStyle(color: AppColors.textMuted),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

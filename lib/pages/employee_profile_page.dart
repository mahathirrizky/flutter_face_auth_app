 import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_face_auth_app/bloc/bloc.dart';
import 'package:go_router/go_router.dart';

class EmployeeProfilePage extends StatelessWidget {
  const EmployeeProfilePage({super.key});

  // Helper for toast messages
  void _showToast(BuildContext context, String message, {ToastificationType type = ToastificationType.info}) {
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dispatch initial data fetch when the page is built
    context.read<EmployeeProfileBloc>().add(LoadEmployeeProfile());

    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController positionController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmNewPasswordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Karyawan'),
        backgroundColor: AppColors.bgMuted,
        foregroundColor: AppColors.textBase,
        toolbarHeight: 45.0,
        elevation: 0.0,
        shadowColor: Colors.transparent,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<EmployeeProfileBloc, EmployeeProfileState>(
            listener: (context, state) {
              if (state is EmployeeProfileLoaded) {
                if (state.successMessage != null) {
                  _showToast(context, state.successMessage!, type: ToastificationType.success);
                }
                if (state.errorMessage != null) {
                  _showToast(context, state.errorMessage!, type: ToastificationType.error);
                }
                // Update controllers when profile data is loaded
                nameController.text = state.name;
                emailController.text = state.email;
                positionController.text = state.position;
              } else if (state is EmployeeProfileError) {
                _showToast(context, state.message, type: ToastificationType.error);
              }
            },
          ),
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Unauthenticated || state is AuthLogoutSuccess) {
                context.go('/login'); // Navigate to login page
              } else if (state is AuthLogoutFailure) {
                _showToast(context, 'Logout Failed: ${state.message}', type: ToastificationType.error);
              }
            },
          ),
        ],
        child: BlocBuilder<EmployeeProfileBloc, EmployeeProfileState>(
          builder: (context, state) {
            if (state is EmployeeProfileLoading) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(state.message, style: TextStyle(color: AppColors.textBase)),
                ],
              ));
            } else if (state is EmployeeProfileLoaded) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Informasi Profil Card
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
                                'Informasi Profil',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textBase,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nama',
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: positionController,
                                decoration: InputDecoration(
                                  labelText: 'Posisi',
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
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<EmployeeProfileBloc>().add(UpdateEmployeeProfile(
                                    name: nameController.text,
                                    email: emailController.text,
                                    position: positionController.text,
                                  ));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: AppColors.textBase,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Update Profil'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Informasi Shift Card
                      if (state.shiftInfo != null)
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
                                  'Informasi Shift',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBase,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Nama Shift:', style: TextStyle(color: AppColors.textMuted)),
                                    Text(state.shiftInfo!['name'] ?? '-', style: TextStyle(color: AppColors.textBase)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Waktu Mulai:', style: TextStyle(color: AppColors.textMuted)),
                                    Text(state.shiftInfo!['start_time'] ?? '-', style: TextStyle(color: AppColors.textBase)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Waktu Selesai:', style: TextStyle(color: AppColors.textMuted)),
                                    Text(state.shiftInfo!['end_time'] ?? '-', style: TextStyle(color: AppColors.textBase)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Ubah Kata Sandi Card
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
                                'Ubah Kata Sandi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textBase,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: newPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Kata Sandi Baru',
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: confirmNewPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Konfirmasi Kata Sandi Baru',
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
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<EmployeeProfileBloc>().add(ChangeEmployeePassword(
                                    newPassword: newPasswordController.text,
                                    confirmNewPassword: confirmNewPasswordController.text,
                                  ));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: AppColors.textBase,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Ubah Kata Sandi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(LogoutRequested());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: AppColors.textBase,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is EmployeeProfileError) {
              return Center(child: Text('Error: ${state.message}', style: TextStyle(color: Colors.red)));
            } else {
              return const Center(child: Text('Initial State'));
            }
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_face_auth_app/bloc/bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();

  final ValueNotifier<bool> obscureOldPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> obscureNewPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> obscureConfirmNewPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isPasswordValid = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showPasswordValidator = ValueNotifier<bool>(false);

  late FocusNode _newPasswordFocusNode;

  @override
  void initState() {
    super.initState();
    _newPasswordFocusNode = FocusNode();
    _newPasswordFocusNode.addListener(() {
      if (_newPasswordFocusNode.hasFocus) {
        _showPasswordValidator.value = true; // Show validator when focused
        // Trigger validation when the field gains focus
        newPasswordController.text = newPasswordController.text; // This will trigger onChanged
      }
    });
    // Dispatch initial data fetch when the page is built
    context.read<EmployeeProfileBloc>().add(LoadEmployeeProfile());
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    positionController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    obscureOldPassword.dispose();
    obscureNewPassword.dispose();
    obscureConfirmNewPassword.dispose();
    isPasswordValid.dispose();
    _showPasswordValidator.dispose();
    _newPasswordFocusNode.dispose();
    super.dispose();
  }

  // Helper for toast messages
  void _showToast(BuildContext context, String message,
      {ToastificationType type = ToastificationType.info}) {
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
    );
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi tidak boleh kosong.';
    }
    if (value != newPasswordController.text) {
      return 'Kata sandi dan konfirmasi kata sandi tidak cocok.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: AppColors.secondary,
                    size: 50,
                  ),
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size.fromHeight(50), // Make the button taller
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
                      Form(
                        key: _formKey,
                        child: Card(
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
                              ValueListenableBuilder<bool>(
                                valueListenable: obscureOldPassword,
                                builder: (context, isObscure, child) {
                                  return TextFormField(
                                    controller: oldPasswordController,
                                    obscureText: isObscure,
                                    decoration: InputDecoration(
                                      labelText: 'Kata Sandi Lama',
                                      labelStyle: TextStyle(color: AppColors.textMuted),
                                      hintStyle: TextStyle(color: AppColors.textMuted),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: AppColors.textMuted),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: AppColors.secondary),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          isObscure ? Icons.visibility_off : Icons.visibility,
                                          color: AppColors.textMuted,
                                        ),
                                        onPressed: () {
                                          obscureOldPassword.value = !isObscure;
                                        },
                                      ),
                                    ),
                                    style: TextStyle(color: AppColors.textBase),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<bool>(
                                valueListenable: obscureNewPassword,
                                builder: (context, isObscure, child) {
                                  return TextFormField(
                                    controller: newPasswordController,
                                    focusNode: _newPasswordFocusNode,
                                    obscureText: isObscure,
                                    onChanged: (value) {
                                      // Trigger validation on change
                                      _formKey.currentState!.validate();
                                    },
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
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          isObscure ? Icons.visibility_off : Icons.visibility,
                                          color: AppColors.textMuted,
                                        ),
                                        onPressed: () {
                                          obscureNewPassword.value = !isObscure;
                                        },
                                      ),
                                    ),
                                    style: TextStyle(color: AppColors.textBase),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              ValueListenableBuilder<bool>(
                                valueListenable: _showPasswordValidator,
                                builder: (context, showValidator, child) {
                                  if (!showValidator) {
                                    return const SizedBox.shrink();
                                  }
                                  return FlutterPwValidator(
                                    controller: newPasswordController,
                                    minLength: 8,
                                    uppercaseCharCount: 1,
                                    lowercaseCharCount: 1,
                                    numericCharCount: 1,
                                    specialCharCount: 0, // No special character required based on old validation
                                    width: 400,
                                    height: 150,
                                    onSuccess: () {
                                      isPasswordValid.value = true;
                                    },
                                    onFail: () {
                                      isPasswordValid.value = false;
                                    },
                                    defaultColor: AppColors.textMuted,
                                    successColor: AppColors.success,
                                    failureColor: AppColors.danger,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<bool>(
                                valueListenable: obscureConfirmNewPassword,
                                builder: (context, isObscure, child) {
                                  return TextFormField(
                                    controller: confirmNewPasswordController,
                                    obscureText: isObscure,
                                    onChanged: (value) {
                                      _formKey.currentState!.validate();
                                    },
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
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          isObscure ? Icons.visibility_off : Icons.visibility,
                                          color: AppColors.textMuted,
                                        ),
                                        onPressed: () {
                                          obscureConfirmNewPassword.value = !isObscure;
                                        },
                                      ),
                                    ),
                                    style: TextStyle(color: AppColors.textBase),
                                    validator: (value) => _validateConfirmPassword(value),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate() && isPasswordValid.value) {
                                    context.read<EmployeeProfileBloc>().add(ChangeEmployeePassword(
                                      oldPassword: oldPasswordController.text,
                                      newPassword: newPasswordController.text,
                                      confirmNewPassword: confirmNewPasswordController.text,
                                    ));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: AppColors.textBase,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size.fromHeight(50), // Make the button taller
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Ubah Kata Sandi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: 
                      () {
                        context.read<AuthBloc>().add(LogoutRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.textBase,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size.fromHeight(50), // Make the button taller
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Keluar')),
                   
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

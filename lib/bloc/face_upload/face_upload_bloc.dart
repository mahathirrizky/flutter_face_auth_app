import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_face_auth_app/repositories/profile_repository.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

part 'face_upload_event.dart';
part 'face_upload_state.dart';

class FaceUploadBloc extends Bloc<FaceUploadEvent, FaceUploadState> {
  final ProfileRepository _profileRepository;

  FaceUploadBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(FaceUploadInitial()) {
    on<UploadFaceImageEvent>(_onUploadFaceImage);
  }

  Future<void> _onUploadFaceImage(
    UploadFaceImageEvent event,
    Emitter<FaceUploadState> emit,
  ) async {
    emit(FaceUploadInProgress());
    try {
      Uint8List? compressedImageBytes;
      try {
        compressedImageBytes = await FlutterImageCompress.compressWithFile(
          event.imageFile.path,
          minWidth: 480,
          quality: 60,
        );
        print('DEBUG: FaceUploadBloc - Image compressed successfully.');
      } catch (e) {
        print('DEBUG: FaceUploadBloc - Error during image compression: $e. Falling back to original bytes.');
        compressedImageBytes = await File(event.imageFile.path).readAsBytes();
      }

      if (compressedImageBytes == null) {
        print('DEBUG: FaceUploadBloc - Compressed image bytes are null.');
        throw Exception("Gagal memproses gambar.");
      }

      final filename = event.imageFile.name;

      await _profileRepository.uploadFaceImage(compressedImageBytes, filename);
      print('DEBUG: FaceUploadBloc - Face image uploaded to repository successfully.');
      emit(FaceUploadSuccess());
      print('DEBUG: FaceUploadBloc - Emitting FaceUploadSuccess state.');
    } catch (e) {
      print('DEBUG: FaceUploadBloc - Caught exception: $e');
      emit(FaceUploadFailure(error: e.toString()));
      print('DEBUG: FaceUploadBloc - Emitting FaceUploadFailure state with error: ${e.toString()}');
    }
  }
}

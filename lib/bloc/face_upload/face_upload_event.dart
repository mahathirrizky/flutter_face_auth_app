part of 'face_upload_bloc.dart';

abstract class FaceUploadEvent extends Equatable {
  const FaceUploadEvent();

  @override
  List<Object> get props => [];
}

class UploadFaceImageEvent extends FaceUploadEvent {
  final XFile imageFile;

  const UploadFaceImageEvent({required this.imageFile});

  @override
  List<Object> get props => [imageFile];
}

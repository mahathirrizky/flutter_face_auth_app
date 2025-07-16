part of 'face_upload_bloc.dart';

abstract class FaceUploadState extends Equatable {
  const FaceUploadState();

  @override
  List<Object> get props => [];
}

class FaceUploadInitial extends FaceUploadState {}

class FaceUploadInProgress extends FaceUploadState {}

class FaceUploadSuccess extends FaceUploadState {}

class FaceUploadFailure extends FaceUploadState {
  final String error;

  const FaceUploadFailure({required this.error});

  @override
  List<Object> get props => [error];
}

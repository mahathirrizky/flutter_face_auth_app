import 'dart:convert';
import 'dart:io'; // Added for File
import 'dart:typed_data'; // Added for Uint8List
import 'package:flutter_face_auth_app/helper/custom_exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Added for MediaType
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Added for image compression
import 'package:path/path.dart' as p; // Added for path operations
import 'api_client.dart';



// Model untuk LeaveRequest, sesuai dengan struktur di backend Go
class LeaveRequest {
  final int id;
  final int employeeId;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final String? sickNotePath; // Added for sick note path

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.sickNotePath,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['ID'],
      employeeId: json['employee_id'],
      type: json['type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      reason: json['reason'],
      status: json['status'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      sickNotePath: json['sick_note_path'],
    );
  }
}

class LeaveRequestRepository {

  LeaveRequestRepository();

  Future<LeaveRequest> applyLeave({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    File? sickNoteFile, // Added for sick note file
  }) async {
    final client = ApiClient(http.Client());
    try {
      final uri = Uri.parse('${ApiClient.baseUrl}/leave-requests');
      final request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['type'] = type;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      request.fields['reason'] = reason;

      // Add sick note file if provided
      if (sickNoteFile != null) {
        Uint8List? fileBytes;
        String? mimeType;

        final fileExtension = p.extension(sickNoteFile.path).toLowerCase();

        if (['.jpg', '.jpeg', '.png'].contains(fileExtension)) {
          // Compress image files
          fileBytes = await FlutterImageCompress.compressWithFile(
            sickNoteFile.path,
            minWidth: 800, // Adjust as needed
            quality: 80,   // Adjust as needed
          );
          if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
            mimeType = 'image/jpeg';
          } else if (fileExtension == '.png') {
            mimeType = 'image/png';
          }
        } else if (fileExtension == '.pdf') {
          // For PDF, just read bytes
          fileBytes = await sickNoteFile.readAsBytes();
          mimeType = 'application/pdf';
        } else {
          // For other types, read bytes and use generic mime type
          fileBytes = await sickNoteFile.readAsBytes();
          mimeType = 'application/octet-stream';
        }

        if (fileBytes == null) {
          throw Exception("Failed to process sick note file.");
        }

        request.files.add(http.MultipartFile.fromBytes(
          'sick_note', // Field name for the file in the backend
          fileBytes,
          filename: sickNoteFile.path.split('/').last,
          contentType: MediaType.parse(mimeType!), // Use parsed mime type
        ));
      }

      // Use ApiClient to send the request with authentication
      final response = await client.sendMultipart(request);

      if (response.statusCode == 201) {
        final body = json.decode(await response.stream.bytesToString());
        return LeaveRequest.fromJson(body['data']);
      } else {
        final errorBody = json.decode(await response.stream.bytesToString());
        final errorMessage = errorBody['message'] ?? 'Failed to submit leave request.';
        throw Exception(errorMessage);
      }
    } finally {
      client.close();
    }
  }

  Future<List<LeaveRequest>> getMyLeaveRequests({String? startDate, String? endDate}) async {
    final client = ApiClient(http.Client());
    try {
      String url = '${ApiClient.baseUrl}/my-leave-requests';
      if (startDate != null && endDate != null) {
        url += '?start_date=$startDate&end_date=$endDate';
      } else if (startDate != null) {
        url += '?start_date=$startDate';
      } else if (endDate != null) {
        url += '?end_date=$endDate';
      }

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => LeaveRequest.fromJson(json)).toList();
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to fetch leave requests.';
        throw CustomException(errorMessage);
      }
    } finally {
      client.close();
    }
  }

  Future<void> cancelLeaveRequest(int requestId) async {
    final client = ApiClient(http.Client());
    try {
      final response = await client.delete(
        Uri.parse('${ApiClient.baseUrl}/leave-requests/$requestId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to cancel leave request.';
        throw CustomException(errorMessage);
      }
    } finally {
      client.close();
    }
  }
}


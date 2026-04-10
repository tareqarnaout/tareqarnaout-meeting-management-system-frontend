import 'dart:convert';
import '../models/meeting.dart';
import 'api_service.dart';

class MeetingService {
  final ApiService _api = ApiService();

  Future<List<Meeting>> getMeetings() async {
    try {
      final response = await _api.get('/meetings');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((dynamic e) => Meeting.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<ArchivedMeeting>> getArchivedMeetings() async {
    try {
      final response = await _api.get('/meetings');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((dynamic e) =>
                ArchivedMeeting.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Meeting?> getMeeting(int id) async {
    try {
      final response = await _api.get('/meetings/$id');
      if (response.statusCode == 200) {
        return Meeting.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createMeeting(Meeting meeting) async {
    try {
      final response = await _api.post('/meetings/', meeting.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Returns status code: 200 = success, 401 = unauthorized, 409 = already signed
  Future<int> verifySignature() async {
    try {
      final response = await _api.post('/meetings/signature/verify', {});
      return response.statusCode;
    } catch (e) {
      return 500;
    }
  }
}

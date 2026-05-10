import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/meeting.dart';
import '../models/meeting_note.dart';
import '../models/minute_taker_models.dart';
import 'api_service.dart';

class MeetingNotesService {
  final ApiService _api = ApiService();

  Future<List<Attendee>> fetchUsers() async {
    try {
      final http.Response response = await _api.get('/meetings/users');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((dynamic e) =>
                Attendee.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      debugPrint('[MeetingNotesService] Failed to fetch users: ${response.statusCode}');
      return <Attendee>[];
    } catch (e) {
      debugPrint('[MeetingNotesService] Error fetching users: $e');
      return <Attendee>[];
    }
  }

  Future<List<MeetingNote>> getAllNotes() async {
    try {
      final http.Response response = await _api.get('/meetings/getMeetingNotes');
      if (response.statusCode == 200) {
        final List<dynamic> data =
            jsonDecode(response.body) as List<dynamic>;
        return data
            .map((dynamic e) =>
                MeetingNote.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      debugPrint(
          '[MeetingNotesService] Failed to load notes: ${response.statusCode}');
      return <MeetingNote>[];
    } catch (e) {
      debugPrint('[MeetingNotesService] Error loading notes: $e');
      return <MeetingNote>[];
    }
  }

  Future<MeetingData> getMeetingData() async {
    try {
      final http.Response response = await _api.get('/meetings/getMeetingData');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<MeetingNote> notes =
            (data['meetingNotes'] as List<dynamic>?)
                    ?.map((dynamic e) =>
                        MeetingNote.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                <MeetingNote>[];
        final List<Meeting> editRequests =
            (data['meetingsController'] as List<dynamic>?)
                    ?.map((dynamic e) =>
                        Meeting.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                <Meeting>[];
        return MeetingData(notes: notes, editRequests: editRequests);
      }
      debugPrint(
          '[MeetingNotesService] Failed to load meeting data: ${response.statusCode}');
      return MeetingData(notes: <MeetingNote>[], editRequests: <Meeting>[]);
    } catch (e) {
      debugPrint('[MeetingNotesService] Error loading meeting data: $e');
      return MeetingData(notes: <MeetingNote>[], editRequests: <Meeting>[]);
    }
  }

  Future<bool> createNote({
    required String notes,
    required List<int> attendeeIds,
    required int recorderId,
    required DateTime date,
  }) async {
    try {
      final http.Response response =
          await _api.post('/meetings/MeetingNotes', <String, dynamic>{
        'notes': notes,
        'attendes': attendeeIds,
        'recorderId': recorderId,
        'date': date.toIso8601String(),
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[MeetingNotesService] Error creating note: $e');
      return false;
    }
  }
}

class MeetingData {
  final List<MeetingNote> notes;
  final List<Meeting> editRequests;

  const MeetingData({required this.notes, required this.editRequests});
}

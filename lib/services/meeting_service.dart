import 'dart:convert';
import '../models/meeting.dart';
import 'api_service.dart';

class MeetingService {
  // Singleton so all screens share the same cache.
  static final MeetingService _instance = MeetingService._();
  factory MeetingService() => _instance;
  MeetingService._();

  final ApiService _api = ApiService();

  static const Duration _ttl = Duration(minutes: 2);

  static List<Meeting>? _meetingsCache;
  static DateTime? _meetingsCacheTime;

  static List<Meeting>? _pendingCache;
  static DateTime? _pendingCacheTime;

  bool _valid(DateTime? t) =>
      t != null && DateTime.now().difference(t) < _ttl;

  void invalidateCache() {
    _meetingsCache = null;
    _meetingsCacheTime = null;
    _pendingCache = null;
    _pendingCacheTime = null;
  }

  Future<List<Meeting>> getMeetings() async {
    if (_valid(_meetingsCacheTime) && _meetingsCache != null) {
      return _meetingsCache!;
    }
    try {
      final response = await _api.get('/meetings');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        _meetingsCache = data
            .map((dynamic e) => Meeting.fromJson(e as Map<String, dynamic>))
            .toList();
        _meetingsCacheTime = DateTime.now();
        return _meetingsCache!;
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

  Future<List<Meeting>> getPendingSignMeetings() async {
    if (_valid(_pendingCacheTime) && _pendingCache != null) {
      return _pendingCache!;
    }
    try {
      final response = await _api.get('/meetings/GetPendingSignMeetings');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        _pendingCache = data
            .map((dynamic e) => Meeting.fromJson(e as Map<String, dynamic>))
            .toList();
        _pendingCacheTime = DateTime.now();
        return _pendingCache!;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Meeting?> getMeeting(int id) async {
    // Check the meetings cache first to avoid a redundant network call.
    if (_meetingsCache != null) {
      try {
        return _meetingsCache!.firstWhere((Meeting m) => m.id == id);
      } catch (_) {
        // Not in cache — fall through to network.
      }
    }

    try {
      final response = await _api.get('/meetings/getMeeting?meetingId=$id');
      if (response.statusCode == 200) {
        return Meeting.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createMeeting(Meeting meeting, {int? editedMeetingId}) async {
    try {
      final String endpoint = editedMeetingId != null
          ? '/meetings/?editedMeetingID=$editedMeetingId'
          : '/meetings/';
      final response = await _api.post(endpoint, meeting.toJson());
      final bool ok =
          response.statusCode == 200 || response.statusCode == 201;
      if (ok) invalidateCache();
      return ok;
    } catch (e) {
      return false;
    }
  }

  /// Returns status code: 200 = success, 401 = unauthorized, 409 = already signed
  Future<int> verifySignature() async {
    try {
      final response = await _api.post('/meetings/signature/verify', {});
      if (response.statusCode == 200) invalidateCache();
      return response.statusCode;
    } catch (e) {
      return 500;
    }
  }

  Future<int> requestEdit(int meetingId, String note) async {
    try {
      final response = await _api.post('/meetings/editMeeting', {
        'meetingId': meetingId,
        'note': note,
      });
      if (response.statusCode == 200) invalidateCache();
      return response.statusCode;
    } catch (e) {
      return 500;
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _api.get('/meetings/users');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<MeetingRelationship>> getMeetingRelationships(
      int meetingId) async {
    try {
      final response =
          await _api.get('/meetings/Relationships?meetingID=$meetingId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((dynamic e) =>
                MeetingRelationship.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<int>?> searchMeetings(String query) async {
    try {
      final response = await _api.post('/meetings/search', {'query': query});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.map((dynamic e) => e as int).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../model/notification_model.dart';

// Local constants to avoid depending on missing global constants file
const String _kApiBaseUrl = 'https://jsonplaceholder.typicode.com';
const String _kPostsEndpoint = '/posts';
const Duration _kTimeout = Duration(seconds: 30);

class NotificationRepository {
  final http.Client _client;
  NotificationRepository({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<NotificationModel>> fetchNotifications() async {
    final uri = Uri.parse('$_kApiBaseUrl$_kPostsEndpoint');
    try {
      final response = await _client.get(uri).timeout(_kTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to fetch notifications: ${response.statusCode}');
    } catch (e) {
      // On any error, return static fallback data
      return getStaticNotifications();
    }
  }

  Future<NotificationModel?> fetchNotificationById(int id) async {
    final uri = Uri.parse('$_kApiBaseUrl$_kPostsEndpoint/$id');
    try {
      final response = await _client.get(uri).timeout(_kTimeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return NotificationModel.fromJson(data);
      }
      if (response.statusCode == 404) return null;
      throw Exception('Failed to fetch notification: ${response.statusCode}');
    } catch (_) {
      return null;
    }
  }

  Future<List<NotificationModel>> getStaticNotifications() async {
    // Generate a larger set of static notifications (useful for offline/demo)
    const total = 50;
    final List<Map<String, dynamic>> staticData = List.generate(total, (i) {
      final id = i + 1;
      return {
        'userId': (i % 10) + 1,
        'id': id,
        'title': 'Sample notification #$id',
        'body':
            'This is a demo notification body for item #$id. Replace with real content in production.',
        'isRead': false,
      };
    });

    await Future.delayed(const Duration(milliseconds: 200));
    return staticData.map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<bool> updateNotification(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_kApiBaseUrl$_kPostsEndpoint/$id');
    try {
      final response = await _client
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(_kTimeout);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNotification(int id) async {
    final uri = Uri.parse('$_kApiBaseUrl$_kPostsEndpoint/$id');
    try {
      final response = await _client.delete(uri).timeout(_kTimeout);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

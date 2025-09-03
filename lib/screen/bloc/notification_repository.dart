import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    debugPrint('NotificationRepository: fetchNotifications() -> $uri');

    // Use a browser-like User-Agent and Accept header. Some servers
    // block unknown clients or return different responses based on headers.
    final headers = {
      'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
      'Accept': 'application/json',
    };

    const int maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: headers)
            .timeout(_kTimeout);
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          debugPrint(
            'NotificationRepository: fetched ${data.length} items from API',
          );
          return data
              .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        final msg = 'Failed to fetch notifications: ${response.statusCode}';
        debugPrint(
          'NotificationRepository: $msg (attempt ${attempt + 1}/$maxAttempts)',
        );
        // If last attempt, throw to trigger fallback below.
        if (attempt == maxAttempts - 1) throw Exception(msg);
      } catch (e) {
        debugPrint('NotificationRepository: attempt ${attempt + 1} failed: $e');
        if (attempt < maxAttempts - 1) {
          final waitMs = 300 * (1 << attempt); // 300ms, 600ms, ...
          await Future.delayed(Duration(milliseconds: waitMs));
          continue;
        }
        // final failure -> fall back to static data
        debugPrint(
          'NotificationRepository: fetchNotifications failed, falling back to static data. Error: $e',
        );
        final fallback = await getStaticNotifications();
        debugPrint(
          'NotificationRepository: returning ${fallback.length} static notifications',
        );
        return fallback;
      }
    }

    // Shouldn't reach here, but return static data defensively.
    final fallback = await getStaticNotifications();
    debugPrint(
      'NotificationRepository: returning ${fallback.length} static notifications',
    );
    return fallback;
  }

  Future<NotificationModel?> fetchNotificationById(int id) async {
    final uri = Uri.parse('$_kApiBaseUrl$_kPostsEndpoint/$id');
    debugPrint('NotificationRepository: fetchNotificationById($id) -> $uri');

    final headers = {
      'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
      'Accept': 'application/json',
    };

    const int maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: headers)
            .timeout(_kTimeout);
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          debugPrint('NotificationRepository: fetched notification id=$id');
          return NotificationModel.fromJson(data);
        }
        if (response.statusCode == 404) {
          debugPrint(
            'NotificationRepository: notification id=$id not found (404)',
          );
          return null;
        }
        final msg = 'Failed to fetch notification: ${response.statusCode}';
        debugPrint(
          'NotificationRepository: $msg (attempt ${attempt + 1}/$maxAttempts)',
        );
        if (attempt == maxAttempts - 1) throw Exception(msg);
      } catch (e) {
        debugPrint(
          'NotificationRepository: fetchNotificationById($id) attempt ${attempt + 1} failed: $e',
        );
        if (attempt < maxAttempts - 1) {
          final waitMs = 300 * (1 << attempt);
          await Future.delayed(Duration(milliseconds: waitMs));
          continue;
        }
        return null;
      }
    }

    return null;
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

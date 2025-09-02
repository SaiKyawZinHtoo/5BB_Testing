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
    final staticData = [
      {
        "userId": 1,
        "id": 1,
        "title":
            "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
        "body":
            "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto",
      },
      {
        "userId": 1,
        "id": 2,
        "title": "qui est esse",
        "body":
            "est rerum tempore vitae\nsequi sint nihil reprehenderit dolor beatae ea dolores neque\nfugiat blanditiis voluptate porro vel nihil molestiae ut reiciendis\nqui aperiam non debitis possimus qui neque nisi nulla",
      },
      {
        "userId": 1,
        "id": 3,
        "title": "ea molestias quasi exercitationem repellat qui ipsa sit aut",
        "body":
            "et iusto sed quo iure\nvoluptatem occaecati omnis eligendi aut ad\nvoluptatem doloribus vel accusantium quis pariatur\nmolestiae porro eius odio et labore et velit aut",
      },
    ];

    await Future.delayed(const Duration(milliseconds: 300));
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

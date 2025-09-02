class NotificationModel {
  final int userId;
  final int id;
  final String title;
  final String body;
  final String date;
  final bool isRead;

  NotificationModel({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    return NotificationModel(
      userId: json['userId'] as int? ?? 0,
      id: id,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      date: '2023-10-${(id % 30) + 1}'.padLeft(2, '0'),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'id': id,
      'title': title,
      'body': body,
      'date': date,
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({
    int? userId,
    int? id,
    String? title,
    String? body,
    String? date,
    bool? isRead,
  }) {
    return NotificationModel(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

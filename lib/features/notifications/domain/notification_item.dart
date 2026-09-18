class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        isRead: json['isRead'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
}

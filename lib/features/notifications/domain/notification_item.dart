class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final String timeLabel;
  final bool isRead;
}

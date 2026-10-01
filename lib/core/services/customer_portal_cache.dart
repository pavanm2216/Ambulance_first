/// In-memory cache for Customer data already confirmed by Supabase.
///
/// This cache is never a source of fabricated records. It is replaced during
/// authenticated Customer initialization and updated only after RPC success.
class CustomerPortalCache {
  CustomerPortalCache._();

  static Map<String, dynamic>? profile;
  static List<Map<String, dynamic>> quotations = <Map<String, dynamic>>[];
  static List<Map<String, dynamic>> notifications = <Map<String, dynamic>>[];
  static final Map<String, List<Map<String, dynamic>>> bookingHistory =
      <String, List<Map<String, dynamic>>>{};

  static void clear() {
    profile = null;
    quotations = <Map<String, dynamic>>[];
    notifications = <Map<String, dynamic>>[];
    bookingHistory.clear();
  }

  static void replaceNotification(Map<String, dynamic> notification) {
    final id = notification['id']?.toString();
    if (id == null || id.isEmpty) {
      return;
    }
    final index = notifications.indexWhere((item) => item['id']?.toString() == id);
    if (index < 0) {
      notifications.add(notification);
    } else {
      notifications[index] = notification;
    }
  }

  static void markNotificationRead(String notificationId) {
    final index = notifications.indexWhere(
      (item) => item['id']?.toString() == notificationId,
    );
    if (index >= 0) {
      notifications[index] = {
        ...notifications[index],
        'read': true,
        'is_read': true,
      };
    }
  }
}

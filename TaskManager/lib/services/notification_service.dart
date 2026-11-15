import 'package:flutter/foundation.dart';

import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _api = ApiClient.instance;

  /// Số thông báo chưa đọc, dùng cho huy hiệu trên chuông.
  static final ValueNotifier<int> unreadNotifier = ValueNotifier<int>(0);

  Future<List<AppNotification>> list({bool unreadOnly = false}) async {
    final data = await _api.get('/notifications', query: {if (unreadOnly) 'unread': 'true'});
    return (data as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> unreadCount() async {
    final data = await _api.get('/notifications/unread-count');
    return ((data as Map<String, dynamic>)['count'] as num).toInt();
  }

  Future<void> refreshUnread() async {
    try {
      unreadNotifier.value = await unreadCount();
    } catch (_) {
      // bỏ qua lỗi mạng khi chỉ cập nhật huy hiệu
    }
  }

  Future<void> markRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.patch('/notifications/read-all');
  }
}

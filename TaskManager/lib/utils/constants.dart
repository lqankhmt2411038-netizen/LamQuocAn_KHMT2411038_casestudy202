import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  /// Nếu chạy trên ĐIỆN THOẠI THẬT: điền IP máy tính chạy backend, ví dụ '192.168.1.10'.
  /// Để rỗng khi chạy máy ảo Android (emulator).
  static const String lanHost = '';
  static const int port = 3000;

  static String get baseUrl {
    if (lanHost.isNotEmpty) return 'http://$lanHost:$port/api';
    // 10.0.2.2 là địa chỉ "localhost của máy tính" nhìn từ máy ảo Android
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:$port/api';
    return 'http://localhost:$port/api';
  }

  static const Map<String, String> statusLabels = {
    'todo': 'Chưa thực hiện',
    'in_progress': 'Đang thực hiện',
    'completed': 'Đã hoàn thành',
  };

  static const Map<String, String> priorityLabels = {
    'low': 'Thấp',
    'medium': 'Trung bình',
    'high': 'Cao',
  };

  static const Map<String, String> roleLabels = {
    'owner': 'Người tạo',
    'editor': 'Người chỉnh sửa',
    'assignee': 'Người được giao',
    'viewer': 'Người xem',
  };

  static const Map<String, String> permissionLabels = {
    'viewer': 'Chỉ xem',
    'editor': 'Chỉnh sửa',
  };
}

import '../utils/date_formatter.dart';

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String avatarUrl;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl = '',
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] ?? '').toString(),
        fullName: (json['fullName'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        avatarUrl: (json['avatarUrl'] ?? '').toString(),
        createdAt: DateFormatter.parse(json['createdAt']),
      );

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.last.substring(0, 1).toUpperCase();
  }
}

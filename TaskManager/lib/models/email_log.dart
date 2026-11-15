import '../utils/date_formatter.dart';

class EmailLog {
  final String id;
  final String recipientEmail;
  final String eventType;
  final String subject;
  final String status;
  final int attempts;
  final String errorMessage;
  final DateTime? sentAt;
  final DateTime? createdAt;

  const EmailLog({
    required this.id,
    required this.recipientEmail,
    required this.eventType,
    required this.subject,
    required this.status,
    required this.attempts,
    this.errorMessage = '',
    this.sentAt,
    this.createdAt,
  });

  factory EmailLog.fromJson(Map<String, dynamic> json) => EmailLog(
        id: (json['id'] ?? '').toString(),
        recipientEmail: (json['recipientEmail'] ?? '').toString(),
        eventType: (json['eventType'] ?? '').toString(),
        subject: (json['subject'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        errorMessage: (json['errorMessage'] ?? '').toString(),
        sentAt: DateFormatter.parse(json['sentAt']),
        createdAt: DateFormatter.parse(json['createdAt']),
      );
}

import 'package:intl/intl.dart';

class DateFormatter {
  static DateTime? parse(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  static String date(DateTime? d) =>
      d == null ? 'Chưa đặt' : DateFormat('dd/MM/yyyy').format(d);

  static String dateTime(DateTime? d) =>
      d == null ? 'Chưa đặt' : DateFormat('dd/MM/yyyy HH:mm').format(d);
}

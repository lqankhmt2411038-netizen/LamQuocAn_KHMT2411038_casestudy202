class Validators {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? required(String? v, [String label = 'Trường này']) {
    if (v == null || v.trim().isEmpty) return '$label không được để trống';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
    if (!_emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (v != original) return 'Mật khẩu xác nhận không khớp';
    return null;
  }
}

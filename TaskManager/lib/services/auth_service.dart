import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiClient _api = ApiClient.instance;
  AppUser? currentUser;

  Future<AppUser> login(String email, String password) async {
    final data = await _api.post('/auth/login', body: {'email': email.trim(), 'password': password});
    await _api.saveToken(data['token'] as String);
    currentUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    return currentUser!;
  }

  Future<AppUser> register(String fullName, String email, String password) async {
    final data = await _api.post('/auth/register', body: {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'password': password,
    });
    await _api.saveToken(data['token'] as String);
    currentUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    return currentUser!;
  }

  /// Khôi phục phiên đăng nhập từ token đã lưu. Trả về null nếu chưa đăng nhập / token hết hạn.
  Future<AppUser?> restoreSession() async {
    await _api.loadToken();
    if (!_api.hasToken) return null;
    try {
      final data = await _api.get('/auth/me', redirectOn401: false);
      currentUser = AppUser.fromJson(data as Map<String, dynamic>);
      return currentUser;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await _api.clearToken();
      return null;
    }
  }

  Future<AppUser> updateProfile({String? fullName, String? avatarUrl}) async {
    final data = await _api.put('/auth/me', body: {
      if (fullName != null) 'fullName': fullName.trim(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl.trim(),
    });
    currentUser = AppUser.fromJson(data as Map<String, dynamic>);
    return currentUser!;
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.put('/auth/change-password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword});
  }

  Future<void> logout() async {
    currentUser = null;
    await _api.clearToken();
  }
}

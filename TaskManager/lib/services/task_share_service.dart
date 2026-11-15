import '../models/task_share.dart';
import 'api_client.dart';

class TaskShareService {
  final ApiClient _api = ApiClient.instance;

  List<TaskShare> _parse(dynamic data) =>
      (data as List).map((e) => TaskShare.fromJson(e as Map<String, dynamic>)).toList();

  Future<List<TaskShare>> list(String taskId) async => _parse(await _api.get('/tasks/$taskId/shares'));

  Future<List<TaskShare>> share(String taskId, List<String> userIds, String permission) async =>
      _parse(await _api.post('/tasks/$taskId/shares', body: {'userIds': userIds, 'permission': permission}));

  Future<List<TaskShare>> updatePermission(String taskId, String shareId, String permission) async =>
      _parse(await _api.patch('/tasks/$taskId/shares/$shareId', body: {'permission': permission}));

  Future<List<TaskShare>> revoke(String taskId, String shareId) async =>
      _parse(await _api.delete('/tasks/$taskId/shares/$shareId'));
}

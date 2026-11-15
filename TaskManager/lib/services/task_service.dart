import '../models/email_log.dart';
import '../models/task.dart';
import '../models/task_activity.dart';
import 'api_client.dart';

class TaskService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Task>> list({
    String? scope,
    String? status,
    String? priority,
    String? q,
    String? assigneeId,
    String sortBy = 'createdAt',
    String order = 'desc',
  }) async {
    final query = <String, String>{
      if (scope != null && scope.isNotEmpty) 'scope': scope,
      if (status != null && status.isNotEmpty) 'status': status,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (assigneeId != null && assigneeId.isNotEmpty) 'assigneeId': assigneeId,
      'sortBy': sortBy,
      'order': order,
    };
    final data = await _api.get('/tasks', query: query);
    return (data as List).map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Task> get(String id) async {
    final data = await _api.get('/tasks/$id');
    return Task.fromJson(data as Map<String, dynamic>);
  }

  Future<Task> create(Map<String, dynamic> payload) async {
    final data = await _api.post('/tasks', body: payload);
    return Task.fromJson(data as Map<String, dynamic>);
  }

  Future<Task> update(String id, Map<String, dynamic> payload) async {
    final data = await _api.put('/tasks/$id', body: payload);
    return Task.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('/tasks/$id');
  }

  Future<Task> updateStatus(String id, String status) async {
    final data = await _api.patch('/tasks/$id/status', body: {'status': status});
    return Task.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TaskActivity>> activities(String id) async {
    final data = await _api.get('/tasks/$id/activities');
    return (data as List).map((e) => TaskActivity.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ----- Giao việc -----
  Future<Task> assign(String taskId, List<String> userIds, {String? primaryAssigneeId}) async {
    final data = await _api.post('/tasks/$taskId/assignees', body: {
      'userIds': userIds,
      if (primaryAssigneeId != null) 'primaryAssigneeId': primaryAssigneeId,
    });
    return Task.fromJson(data as Map<String, dynamic>);
  }

  Future<Task> setPrimaryAssignee(String taskId, String userId) async {
    final data = await _api.patch('/tasks/$taskId/assignees/$userId', body: {'isPrimary': true});
    return Task.fromJson(data as Map<String, dynamic>);
  }

  Future<Task> unassign(String taskId, String userId) async {
    final data = await _api.delete('/tasks/$taskId/assignees/$userId');
    return Task.fromJson(data as Map<String, dynamic>);
  }

  // ----- Email -----
  Future<List<EmailLog>> emailLogs(String taskId) async {
    final data = await _api.get('/tasks/$taskId/email-logs');
    return (data as List).map((e) => EmailLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EmailLog> retryEmail(String logId) async {
    final data = await _api.post('/email-logs/$logId/retry');
    return EmailLog.fromJson(data as Map<String, dynamic>);
  }
}

import 'api_client.dart';

class StatisticsService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> tasks() async =>
      Map<String, dynamic>.from(await _api.get('/statistics/tasks') as Map);

  Future<Map<String, dynamic>> assignments() async =>
      Map<String, dynamic>.from(await _api.get('/statistics/assignments') as Map);

  Future<Map<String, dynamic>> deadlines() async =>
      Map<String, dynamic>.from(await _api.get('/statistics/deadlines') as Map);
}

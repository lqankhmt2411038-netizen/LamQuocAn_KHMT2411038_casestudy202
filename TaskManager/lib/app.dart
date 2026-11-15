import 'package:flutter/material.dart';

import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/tasks/task_list_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'widgets/loading_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  @override
  void initState() {
    super.initState();
    // Token hết hạn / không hợp lệ -> quay về đăng nhập
    ApiClient.instance.onUnauthorized = () {
      AuthService.instance.currentUser = null;
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(message: 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại'),
        ),
        (route) => false,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(isDense: false),
      ),
      home: const _SplashGate(),
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  late final Future<AppUser?> _future;

  @override
  void initState() {
    super.initState();
    _future = AuthService.instance.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: LoadingView(message: 'Đang khởi động...'));
        }
        return snapshot.data != null ? const TaskListScreen() : const LoginScreen();
      },
    );
  }
}

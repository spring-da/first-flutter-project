import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_controller.dart';
import 'data/repositories/app_repository.dart';
import 'data/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = LocalAppRepository(SharedPreferencesStorage());
  final controller = AppController(repository);
  await controller.load();

  runApp(DevNestApp(controller: controller));
}

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_controller.dart';
import 'core/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = AppController(SharedPreferencesStorage());
  await controller.load();

  runApp(DevNestApp(controller: controller));
}

import 'package:first_demo/app.dart';
import 'package:first_demo/core/app_controller.dart';
import 'package:first_demo/core/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppController controller;

  setUp(() async {
    controller = AppController(MemoryStorage());
    await controller.load();
  });

  testWidgets('shows the DevNest dashboard', (tester) async {
    await tester.pumpWidget(DevNestApp(controller: controller));

    expect(find.text('DevNest'), findsOneWidget);
    expect(find.textContaining('开发者'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('今日清单'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('今日清单'), findsOneWidget);
    expect(find.text('代码库'), findsOneWidget);
  });

  testWidgets('can complete a dashboard task', (tester) async {
    await tester.pumpWidget(DevNestApp(controller: controller));

    expect(controller.completedTasks, 0);
    await tester.scrollUntilVisible(
      find.text('梳理本周最重要的技术目标'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(controller.completedTasks, 1);
  });

  testWidgets('navigates to focus mode', (tester) async {
    await tester.pumpWidget(DevNestApp(controller: controller));

    await tester.tap(find.text('专注').last);
    await tester.pumpAndSettle();

    expect(find.text('深度工作'), findsOneWidget);
    expect(find.text('开始专注'), findsOneWidget);
  });
}

import 'package:first_demo/app.dart';
import 'package:first_demo/core/app_controller.dart';
import 'package:first_demo/core/storage_service.dart';
import 'package:first_demo/screens/projects_screen.dart';
import 'package:first_demo/screens/vault_screen.dart';
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

    expect(find.text('DevNest'), findsWidgets);
    expect(find.textContaining('开发者'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('今日清单'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('今日清单'), findsOneWidget);
    expect(find.text('知识库'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
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

  testWidgets('navigates to the project radar', (tester) async {
    await tester.pumpWidget(DevNestApp(controller: controller));

    await tester.tap(find.text('项目').last);
    await tester.pumpAndSettle();

    expect(find.text('项目雷达'), findsOneWidget);
    expect(find.text('PROJECT RADAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits an existing project', (tester) async {
    final original = controller.projects.first;
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('项目').last);
    await tester.pumpAndSettle();

    final projectScrollable = find
        .descendant(
          of: find.byType(ProjectsScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(original.name),
      250,
      scrollable: projectScrollable,
    );
    await tester.tap(find.byTooltip('项目操作').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'DevNest Pro');
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    expect(
      controller.projects.firstWhere((item) => item.id == original.id).name,
      'DevNest Pro',
    );
  });

  testWidgets('cancelling add snippet does not throw or add data', (
    tester,
  ) async {
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();

    final initialCount = controller.snippets.length;
    await tester.tap(find.byTooltip('新增片段'));
    await tester.pumpAndSettle();
    expect(find.text('新增代码片段'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.snippets.length, initialCount);
  });

  testWidgets('expands a snippet to show the full code viewer', (tester) async {
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();

    final vaultScrollable = find
        .descendant(
          of: find.byType(VaultScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Dart 并发请求'),
      250,
      scrollable: vaultScrollable,
    );
    await tester.drag(vaultScrollable, const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.text('展开全部').first);
    await tester.pumpAndSettle();

    expect(find.text('完整代码'), findsOneWidget);
    expect(find.text('复制全部代码'), findsOneWidget);
  });

  testWidgets('edits an existing snippet and keeps its favorite state', (
    tester,
  ) async {
    final original = controller.snippets.firstWhere((item) => item.isFavorite);
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();

    final vaultScrollable = find
        .descendant(
          of: find.byType(VaultScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(original.title),
      250,
      scrollable: vaultScrollable,
    );
    await tester.tap(find.byTooltip('更多').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    expect(find.text('编辑代码片段'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '更新后的并发请求');
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    final updated = controller.snippets.firstWhere(
      (item) => item.id == original.id,
    );
    expect(updated.title, '更新后的并发请求');
    expect(updated.isFavorite, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling snippet deletion keeps the data', (tester) async {
    final original = controller.snippets.first;
    final initialCount = controller.snippets.length;
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();

    final vaultScrollable = find
        .descendant(
          of: find.byType(VaultScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(original.title),
      250,
      scrollable: vaultScrollable,
    );

    await tester.tap(find.byTooltip('更多').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.text('删除代码片段？'), findsOneWidget);
    expect(find.text('「${original.title}」将被永久删除，此操作无法撤销。'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(controller.snippets.length, initialCount);
    expect(controller.snippets.any((item) => item.id == original.id), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deletes a snippet only after confirmation', (tester) async {
    final original = controller.snippets.first;
    final initialCount = controller.snippets.length;
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();

    final vaultScrollable = find
        .descendant(
          of: find.byType(VaultScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(original.title),
      250,
      scrollable: vaultScrollable,
    );
    await tester.tap(find.byTooltip('更多').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(controller.snippets.length, initialCount - 1);
    expect(controller.snippets.any((item) => item.id == original.id), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard has no overflow on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('收藏片段'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches between snippets and logs inside knowledge base', (
    tester,
  ) async {
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();

    expect(find.text('搜索标题、语言或代码…'), findsOneWidget);
    await tester.tap(find.text('开发日志'));
    await tester.pumpAndSettle();

    expect(find.text('QUICK CAPTURE'), findsOneWidget);
    expect(find.text('时间线'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard log shortcut opens the log knowledge view', (
    tester,
  ) async {
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.scrollUntilVisible(
      find.text('写开发日志'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('写开发日志'));
    await tester.pumpAndSettle();

    expect(find.text('知识库'), findsWidgets);
    expect(find.text('QUICK CAPTURE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a log keeps code snippets unchanged', (tester) async {
    final snippetCount = controller.snippets.length;
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开发日志'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '完成知识库导航合并');
    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();

    expect(controller.logs.single.content, '完成知识库导航合并');
    expect(controller.snippets.length, snippetCount);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.text('完成知识库导航合并'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits and displays the local developer profile', (tester) async {
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();

    expect(find.text('数据足迹'), findsOneWidget);
    await tester.tap(find.byTooltip('编辑资料'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'SpringDa');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(controller.profile.name, 'SpringDa');
    expect(find.text('SpringDa'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('隐私模式'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('隐私模式'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('knowledge and profile pages fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    expect(find.text('数据足迹'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('migrates legacy local data without losing existing tasks', () async {
    final storage = MemoryStorage()
      ..value = {
        'tasks': [
          {'id': 'legacy-task', 'title': '保留旧任务', 'isDone': true},
        ],
        'snippets': <Object?>[],
        'logs': <Object?>[],
      };
    final migrated = AppController(storage);

    await migrated.load();

    expect(migrated.tasks.single.title, '保留旧任务');
    expect(migrated.projects, isNotEmpty);
    expect(migrated.profile.name, '开发者');
    expect(storage.value, containsPair('profile', isA<Map>()));
    expect(storage.value, containsPair('projects', isA<List>()));
  });

  test('persists edited developer profile across app restarts', () async {
    final storage = MemoryStorage();
    final firstSession = AppController(storage);
    await firstSession.load();
    firstSession.updateProfile(
      name: 'SpringDa',
      role: 'Flutter Developer',
      bio: 'Ship and learn.',
    );
    await Future<void>.delayed(Duration.zero);

    final nextSession = AppController(storage);
    await nextSession.load();

    expect(nextSession.profile.name, 'SpringDa');
    expect(nextSession.profile.role, 'Flutter Developer');
    expect(nextSession.profile.bio, 'Ship and learn.');
  });
}

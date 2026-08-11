import 'package:first_demo/app.dart';
import 'package:first_demo/core/app_controller.dart';
import 'package:first_demo/data/repositories/app_repository.dart';
import 'package:first_demo/data/services/storage_service.dart';
import 'package:first_demo/models/dev_models.dart';
import 'package:first_demo/screens/dev_log_screen.dart';
import 'package:first_demo/screens/projects_screen.dart';
import 'package:first_demo/screens/vault_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppController controller;

  setUp(() async {
    controller = _controllerFor(MemoryStorage());
    await controller.load();
  });

  testWidgets('shows the DevNest dashboard', (tester) async {
    await tester.pumpWidget(DevNestApp(controller: controller));

    expect(find.text('DevNest'), findsWidgets);
    expect(find.textContaining('springda'), findsOneWidget);
    expect(find.text('SPRINGDA EDITION'), findsOneWidget);
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
    expect(find.byType(AlertDialog), findsNothing);

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
    await tester.tap(find.text('更新片段'));
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

    expect(find.byTooltip('新增开发日志'), findsOneWidget);
    expect(find.byKey(const ValueKey('log-content-input')), findsNothing);
    expect(find.byKey(const ValueKey('log-search-input')), findsOneWidget);
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
    expect(find.byTooltip('新增开发日志'), findsOneWidget);
    expect(find.byKey(const ValueKey('log-content-input')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling the full-screen log editor keeps data unchanged', (
    tester,
  ) async {
    final initialCount = controller.logs.length;
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开发日志'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增开发日志'));
    await tester.pumpAndSettle();
    expect(find.text('新增开发日志'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(controller.logs.length, initialCount);
    expect(find.byTooltip('新增开发日志'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a log keeps code snippets unchanged', (tester) async {
    final snippetCount = controller.snippets.length;
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开发日志'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增开发日志'));
    await tester.pumpAndSettle();
    expect(find.text('新增开发日志'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('log-title-input')),
      '知识库导航决策',
    );
    await tester.tap(find.text('技术决策').first);
    await tester.enterText(
      find.byKey(const ValueKey('log-content-input')),
      '完成知识库导航合并',
    );
    await tester.enterText(
      find.byKey(const ValueKey('log-tags-input')),
      'Flutter, 架构 Flutter',
    );
    await tester.ensureVisible(find.text('保存日志'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存日志'));
    await tester.pumpAndSettle();

    expect(controller.logs.single.content, '完成知识库导航合并');
    expect(controller.logs.single.title, '知识库导航决策');
    expect(controller.logs.single.category, DevLogCategory.decision);
    expect(controller.logs.single.tags, ['Flutter', '架构']);
    expect(controller.snippets.length, snippetCount);
    final logScrollable = find
        .descendant(
          of: find.byType(DevLogScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('知识库导航决策'),
      250,
      scrollable: logScrollable,
    );
    expect(find.text('知识库导航决策'), findsOneWidget);
    expect(find.text('#Flutter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long development logs collapse and expand', (tester) async {
    final longContent = List.generate(
      12,
      (index) => '第 ${index + 1} 段：记录问题背景、排查过程、方案取舍和最终结果。',
    ).join('\n');
    controller.addLog(
      longContent,
      title: '一次完整的性能问题复盘',
      category: DevLogCategory.problem,
      tags: const ['性能', 'Flutter'],
    );
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开发日志'));
    await tester.pumpAndSettle();

    final logScrollable = find
        .descendant(
          of: find.byType(DevLogScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('一次完整的性能问题复盘'),
      350,
      scrollable: logScrollable,
    );
    await tester.scrollUntilVisible(
      find.text('展开全文'),
      180,
      scrollable: logScrollable,
    );
    await tester.drag(logScrollable, const Offset(0, -220));
    await tester.pumpAndSettle();
    expect(find.text('展开全文'), findsOneWidget);

    await tester.tap(find.text('展开全文'));
    await tester.pumpAndSettle();
    expect(find.text('收起'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('searches and filters structured development logs', (
    tester,
  ) async {
    controller.addLog(
      '定位列表渲染时的掉帧原因',
      title: '排查渲染卡顿',
      category: DevLogCategory.problem,
      tags: const ['性能'],
    );
    controller.addLog(
      '决定继续使用 ChangeNotifier 保持依赖精简',
      title: '状态管理选择',
      category: DevLogCategory.decision,
      tags: const ['架构'],
    );
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开发日志'));
    await tester.pumpAndSettle();

    final logScrollable = find
        .descendant(
          of: find.byType(DevLogScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('log-search-input')),
      300,
      scrollable: logScrollable,
    );
    await tester.enterText(
      find.byKey(const ValueKey('log-search-input')),
      '卡顿',
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('排查渲染卡顿'),
      250,
      scrollable: logScrollable,
    );
    expect(find.text('找到 1 条记录'), findsOneWidget);
    expect(find.text('状态管理选择'), findsNothing);

    await tester.tap(find.byTooltip('清空日志搜索'));
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final decisionFilter = find.byKey(
      const ValueKey('log-category-filter-decision'),
    );
    await tester.drag(logScrollable, const Offset(0, 220));
    await tester.pumpAndSettle();
    await tester.tap(decisionFilter);
    await tester.pumpAndSettle();
    final selectedFilter = tester.widget<ChoiceChip>(decisionFilter);
    expect(selectedFilter.selected, isTrue);
    await tester.scrollUntilVisible(
      find.text('状态管理选择'),
      250,
      scrollable: logScrollable,
    );
    expect(find.text('排查渲染卡顿'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can pin edit and safely delete a development log', (
    tester,
  ) async {
    controller.addLog('原始正文', title: '原始日志');
    final originalId = controller.logs.single.id;
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开发日志'));
    await tester.pumpAndSettle();

    final logScrollable = find
        .descendant(
          of: find.byType(DevLogScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('原始日志'),
      350,
      scrollable: logScrollable,
    );
    await tester.tap(find.byTooltip('日志操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('置顶').last);
    await tester.pumpAndSettle();
    expect(controller.logs.single.isPinned, isTrue);

    await tester.tap(find.byTooltip('日志操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '编辑后的日志');
    await tester.enterText(find.byType(TextFormField).at(1), '编辑后的正文');
    await tester.tap(find.text('更新日志'));
    await tester.pumpAndSettle();
    expect(controller.logs.single.title, '编辑后的日志');
    expect(controller.logs.single.updatedAt, isNotNull);

    await tester.tap(find.byTooltip('日志操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除开发日志？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(controller.logs.single.id, originalId);

    await tester.tap(find.byTooltip('日志操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(controller.logs, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits and displays the local developer profile', (tester) async {
    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();

    expect(find.text('数据足迹'), findsOneWidget);
    expect(find.bySemanticsLabel('springda 的头像'), findsOneWidget);
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

  testWidgets('knowledge editors fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(DevNestApp(controller: controller));
    await tester.tap(find.text('知识库').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('新增片段'));
    await tester.pumpAndSettle();
    expect(find.text('保存片段'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('开发日志'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('新增开发日志'));
    await tester.pumpAndSettle();
    expect(find.text('保存日志'), findsOneWidget);
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
    final migrated = _controllerFor(storage);

    await migrated.load();

    expect(migrated.tasks.single.title, '保留旧任务');
    expect(migrated.projects, isNotEmpty);
    expect(migrated.profile.name, 'springda');
    expect(storage.value, containsPair('profile', isA<Map>()));
    expect(storage.value, containsPair('projects', isA<List>()));
  });

  test('persists edited developer profile across app restarts', () async {
    final storage = MemoryStorage();
    final firstSession = _controllerFor(storage);
    await firstSession.load();
    firstSession.updateProfile(
      name: 'SpringDa',
      role: 'Flutter Developer',
      bio: 'Ship and learn.',
    );
    await Future<void>.delayed(Duration.zero);

    final nextSession = _controllerFor(storage);
    await nextSession.load();

    expect(nextSession.profile.name, 'SpringDa');
    expect(nextSession.profile.role, 'Flutter Developer');
    expect(nextSession.profile.bio, 'Ship and learn.');
  });

  test('upgrades the legacy default profile to springda', () async {
    final storage = MemoryStorage()
      ..value = {
        'tasks': <Object?>[],
        'snippets': <Object?>[],
        'projects': <Object?>[],
        'logs': <Object?>[],
        'profile': {
          'name': '开发者',
          'role': 'Independent Builder',
          'bio': '持续构建，持续学习。',
        },
      };
    final migrated = _controllerFor(storage);

    await migrated.load();

    expect(migrated.profile.name, 'springda');
    expect(migrated.profile.role, 'Independent Developer');
    expect(
      (storage.value!['profile'] as Map)['name'],
      DeveloperProfile.initial.name,
    );
  });

  test('loads legacy text-only development logs safely', () async {
    final createdAt = DateTime(2025, 6, 1, 9, 30);
    final storage = MemoryStorage()
      ..value = {
        'tasks': <Object?>[],
        'snippets': <Object?>[],
        'projects': <Object?>[],
        'logs': [
          {
            'id': 'legacy-log',
            'content': '旧版本只有正文的日志',
            'createdAt': createdAt.toIso8601String(),
          },
        ],
        'profile': DeveloperProfile.initial.toJson(),
      };
    final migrated = _controllerFor(storage);

    await migrated.load();

    final entry = migrated.logs.single;
    expect(entry.content, '旧版本只有正文的日志');
    expect(entry.displayTitle, '旧版本只有正文的日志');
    expect(entry.category, DevLogCategory.learning);
    expect(entry.tags, isEmpty);
    expect(entry.createdAt, createdAt);
  });

  test('persists controller changes through the repository contract', () async {
    final repository = RecordingAppRepository(
      const DevNestData(
        tasks: [],
        snippets: [],
        projects: [],
        logs: [],
        profile: DeveloperProfile.initial,
      ),
    );
    final repositoryController = AppController(repository);

    await repositoryController.load();
    repositoryController.addTask('验证 Repository 边界');
    await Future<void>.delayed(Duration.zero);

    expect(repository.loadCount, 1);
    expect(repository.saveCount, 1);
    expect(repository.savedData?.tasks.single.title, '验证 Repository 边界');
  });
}

AppController _controllerFor(AppStorage storage) {
  return AppController(LocalAppRepository(storage));
}

class RecordingAppRepository implements AppRepository {
  RecordingAppRepository(this.data);

  DevNestData? data;
  DevNestData? savedData;
  int loadCount = 0;
  int saveCount = 0;

  @override
  Future<DevNestData?> load() async {
    loadCount++;
    return data;
  }

  @override
  Future<void> save(DevNestData data) async {
    saveCount++;
    savedData = data;
    this.data = data;
  }
}

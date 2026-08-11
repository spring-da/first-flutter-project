import '../../models/dev_models.dart';
import '../services/storage_service.dart';

/// DevNest 当前完整的领域数据快照。
///
/// UI 和 Controller 不再了解 JSON、SharedPreferences 或具体数据库结构。
class DevNestData {
  const DevNestData({
    required this.tasks,
    required this.snippets,
    required this.projects,
    required this.logs,
    required this.profile,
  });

  factory DevNestData.seeded() {
    return const DevNestData(
      tasks: [
        DevTask(id: 'task-1', title: '梳理本周最重要的技术目标'),
        DevTask(id: 'task-2', title: '推进当前项目的下一步行动'),
        DevTask(id: 'task-3', title: '记录今天解决的关键问题'),
      ],
      snippets: [
        CodeSnippet(
          id: 'snippet-1',
          title: 'Dart 并发请求',
          language: 'Dart',
          code:
              'final results = await Future.wait([\n  fetchUser(),\n  fetchProjects(),\n]);',
          isFavorite: true,
        ),
        CodeSnippet(
          id: 'snippet-2',
          title: 'Git 整理最近提交',
          language: 'Shell',
          code: 'git log --oneline --graph --decorate -12',
        ),
        CodeSnippet(
          id: 'snippet-3',
          title: 'Docker 清理构建缓存',
          language: 'Shell',
          code: 'docker builder prune --filter until=24h',
        ),
      ],
      projects: defaultProjects,
      logs: [],
      profile: DeveloperProfile.initial,
    );
  }

  factory DevNestData.fromJson(Map<String, Object?> json) {
    final profileValue = json['profile'];
    var profile = profileValue is Map
        ? DeveloperProfile.fromJson(Map<String, Object?>.from(profileValue))
        : DeveloperProfile.initial;

    if (_isLegacyDefaultProfile(profile)) {
      profile = DeveloperProfile.initial;
    }

    return DevNestData(
      tasks: _decodeList(json['tasks'], DevTask.fromJson),
      snippets: _decodeList(json['snippets'], CodeSnippet.fromJson),
      projects: json.containsKey('projects')
          ? _decodeList(json['projects'], DevProject.fromJson)
          : defaultProjects,
      logs: _decodeList(json['logs'], DevLogEntry.fromJson),
      profile: profile,
    );
  }

  static const defaultProjects = [
    DevProject(
      id: 'project-1',
      name: 'DevNest',
      description: '为程序员打造的私人工作台，集中管理项目、任务、代码片段与开发日志。',
      techStack: ['Flutter', 'Dart', 'Material 3'],
      status: ProjectStatus.building,
      progress: 68,
      nextAction: '完善项目雷达，并增加数据导出能力',
    ),
    DevProject(
      id: 'project-2',
      name: 'Next Side Project',
      description: '保存下一个值得验证的产品想法，先定义问题，再决定技术方案。',
      techStack: ['Idea'],
      status: ProjectStatus.planning,
      progress: 15,
      nextAction: '写出一句话价值主张和最小用户路径',
    ),
  ];

  final List<DevTask> tasks;
  final List<CodeSnippet> snippets;
  final List<DevProject> projects;
  final List<DevLogEntry> logs;
  final DeveloperProfile profile;

  Map<String, Object?> toJson() => {
    'tasks': tasks.map((task) => task.toJson()).toList(),
    'snippets': snippets.map((snippet) => snippet.toJson()).toList(),
    'projects': projects.map((project) => project.toJson()).toList(),
    'logs': logs.map((entry) => entry.toJson()).toList(),
    'profile': profile.toJson(),
  };
}

/// Controller 依赖的数据契约。
///
/// 未来可以新增 RemoteAppRepository（REST/MySQL）或
/// OfflineFirstAppRepository（远端 + SQLite），而无需修改页面。
abstract interface class AppRepository {
  Future<DevNestData?> load();

  Future<void> save(DevNestData data);
}

/// 使用本地键值数据源实现的 Repository。
class LocalAppRepository implements AppRepository {
  LocalAppRepository(this._storage);

  final AppStorage _storage;

  @override
  Future<DevNestData?> load() async {
    final json = await _storage.load();
    if (json == null) return null;

    final needsMigration =
        !json.containsKey('projects') ||
        json['profile'] is! Map ||
        _containsLegacyDefaultProfile(json['profile']);
    final data = DevNestData.fromJson(json);

    if (needsMigration) {
      await save(data);
    }
    return data;
  }

  @override
  Future<void> save(DevNestData data) {
    return _storage.save(data.toJson());
  }
}

List<T> _decodeList<T>(
  Object? value,
  T Function(Map<String, Object?> json) fromJson,
) {
  if (value is! List) return [];
  return value
      .whereType<Map>()
      .map((item) => fromJson(Map<String, Object?>.from(item)))
      .toList();
}

bool _containsLegacyDefaultProfile(Object? value) {
  if (value is! Map) return false;
  return _isLegacyDefaultProfile(
    DeveloperProfile.fromJson(Map<String, Object?>.from(value)),
  );
}

bool _isLegacyDefaultProfile(DeveloperProfile profile) {
  return profile.name == '开发者' &&
      profile.role == 'Independent Builder' &&
      profile.bio == '持续构建，持续学习。';
}

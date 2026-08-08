import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/dev_models.dart';
import 'storage_service.dart';

class AppController extends ChangeNotifier {
  AppController(this._storage);

  final AppStorage _storage;

  List<DevTask> _tasks = const [];
  List<CodeSnippet> _snippets = const [];
  List<DevProject> _projects = const [];
  List<DevLogEntry> _logs = const [];
  DeveloperProfile _profile = DeveloperProfile.initial;

  List<DevTask> get tasks => List.unmodifiable(_tasks);
  List<CodeSnippet> get snippets => List.unmodifiable(_snippets);
  List<DevProject> get projects => List.unmodifiable(_projects);
  List<DevLogEntry> get logs => List.unmodifiable(_logs);
  DeveloperProfile get profile => _profile;
  int get completedTasks => _tasks.where((task) => task.isDone).length;
  int get favoriteSnippets => _snippets.where((item) => item.isFavorite).length;
  int get activeProjects => _projects
      .where((project) => project.status == ProjectStatus.building)
      .length;

  DevProject? get primaryProject {
    final building = _projects.where(
      (project) => project.status == ProjectStatus.building,
    );
    if (building.isNotEmpty) return building.first;
    final active = _projects.where(
      (project) => project.status != ProjectStatus.completed,
    );
    return active.firstOrNull;
  }

  double get taskProgress {
    if (_tasks.isEmpty) return 0;
    return completedTasks / _tasks.length;
  }

  Future<void> load() async {
    try {
      final value = await _storage.load();
      if (value == null) {
        _seedDemoData();
        await _persist();
        return;
      }

      _tasks = _decodeList(value['tasks'], DevTask.fromJson);
      _snippets = _decodeList(value['snippets'], CodeSnippet.fromJson);
      _projects = _decodeList(value['projects'], DevProject.fromJson);
      _logs = _decodeList(value['logs'], DevLogEntry.fromJson);
      var needsMigration = false;
      if (!value.containsKey('projects')) {
        _projects = _defaultProjects();
        needsMigration = true;
      }
      final profileValue = value['profile'];
      if (profileValue is Map) {
        _profile = DeveloperProfile.fromJson(
          Map<String, Object?>.from(profileValue),
        );
      } else {
        _profile = DeveloperProfile.initial;
        needsMigration = true;
      }
      if (needsMigration) await _persist();
    } catch (_) {
      _seedDemoData();
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

  void _seedDemoData() {
    _tasks = const [
      DevTask(id: 'task-1', title: '梳理本周最重要的技术目标'),
      DevTask(id: 'task-2', title: '推进当前项目的下一步行动'),
      DevTask(id: 'task-3', title: '记录今天解决的关键问题'),
    ];
    _snippets = const [
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
    ];
    _projects = _defaultProjects();
    _logs = [];
    _profile = DeveloperProfile.initial;
  }

  List<DevProject> _defaultProjects() {
    return const [
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
  }

  void addTask(String title) {
    final normalized = title.trim();
    if (normalized.isEmpty) return;
    _tasks = [..._tasks, DevTask(id: _newId('task'), title: normalized)];
    _commit();
  }

  void toggleTask(String id) {
    _tasks = [
      for (final task in _tasks)
        if (task.id == id) task.copyWith(isDone: !task.isDone) else task,
    ];
    _commit();
  }

  void deleteTask(String id) {
    _tasks = _tasks.where((task) => task.id != id).toList();
    _commit();
  }

  void addSnippet({
    required String title,
    required String language,
    required String code,
  }) {
    if (title.trim().isEmpty || code.trim().isEmpty) return;
    _snippets = [
      CodeSnippet(
        id: _newId('snippet'),
        title: title.trim(),
        language: language.trim().isEmpty ? 'Text' : language.trim(),
        code: code.trim(),
      ),
      ..._snippets,
    ];
    _commit();
  }

  void toggleSnippetFavorite(String id) {
    _snippets = [
      for (final snippet in _snippets)
        if (snippet.id == id)
          snippet.copyWith(isFavorite: !snippet.isFavorite)
        else
          snippet,
    ];
    _commit();
  }

  void updateSnippet({
    required String id,
    required String title,
    required String language,
    required String code,
  }) {
    final normalizedTitle = title.trim();
    final normalizedCode = code.trim();
    if (normalizedTitle.isEmpty || normalizedCode.isEmpty) return;

    _snippets = [
      for (final snippet in _snippets)
        if (snippet.id == id)
          snippet.copyWith(
            title: normalizedTitle,
            language: language.trim().isEmpty ? 'Text' : language.trim(),
            code: normalizedCode,
          )
        else
          snippet,
    ];
    _commit();
  }

  void deleteSnippet(String id) {
    _snippets = _snippets.where((snippet) => snippet.id != id).toList();
    _commit();
  }

  void addProject({
    required String name,
    required String description,
    required List<String> techStack,
    required ProjectStatus status,
    required int progress,
    required String nextAction,
  }) {
    if (name.trim().isEmpty || nextAction.trim().isEmpty) return;
    _projects = [
      DevProject(
        id: _newId('project'),
        name: name.trim(),
        description: description.trim(),
        techStack: techStack,
        status: status,
        progress: progress.clamp(0, 100),
        nextAction: nextAction.trim(),
      ),
      ..._projects,
    ];
    _commit();
  }

  void updateProject({
    required String id,
    required String name,
    required String description,
    required List<String> techStack,
    required ProjectStatus status,
    required int progress,
    required String nextAction,
  }) {
    if (name.trim().isEmpty || nextAction.trim().isEmpty) return;
    _projects = [
      for (final project in _projects)
        if (project.id == id)
          project.copyWith(
            name: name.trim(),
            description: description.trim(),
            techStack: techStack,
            status: status,
            progress: progress.clamp(0, 100),
            nextAction: nextAction.trim(),
          )
        else
          project,
    ];
    _commit();
  }

  void deleteProject(String id) {
    _projects = _projects.where((project) => project.id != id).toList();
    _commit();
  }

  void addLog(String content) {
    final normalized = content.trim();
    if (normalized.isEmpty) return;
    _logs = [
      DevLogEntry(
        id: _newId('log'),
        content: normalized,
        createdAt: DateTime.now(),
      ),
      ..._logs,
    ];
    _commit();
  }

  void updateProfile({
    required String name,
    required String role,
    required String bio,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return;
    _profile = DeveloperProfile(
      name: normalizedName,
      role: role.trim().isEmpty ? DeveloperProfile.initial.role : role.trim(),
      bio: bio.trim().isEmpty ? DeveloperProfile.initial.bio : bio.trim(),
    );
    _commit();
  }

  void _commit() {
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() {
    return _storage.save({
      'tasks': _tasks.map((task) => task.toJson()).toList(),
      'snippets': _snippets.map((snippet) => snippet.toJson()).toList(),
      'projects': _projects.map((project) => project.toJson()).toList(),
      'logs': _logs.map((entry) => entry.toJson()).toList(),
      'profile': _profile.toJson(),
    });
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}

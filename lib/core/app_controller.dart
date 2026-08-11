import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/app_repository.dart';
import '../models/dev_models.dart';

class AppController extends ChangeNotifier {
  AppController(this._repository);

  final AppRepository _repository;

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
      final storedData = await _repository.load();
      final data = storedData ?? DevNestData.seeded();
      _apply(data);
      if (storedData == null) await _persist();
    } catch (_) {
      _apply(DevNestData.seeded());
    }
  }

  void _apply(DevNestData data) {
    _tasks = data.tasks;
    _snippets = data.snippets;
    _projects = data.projects;
    _logs = data.logs;
    _profile = data.profile;
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

  void addLog(
    String content, {
    String title = '',
    DevLogCategory category = DevLogCategory.learning,
    List<String> tags = const [],
  }) {
    final normalized = content.trim();
    if (normalized.isEmpty) return;
    _logs = [
      DevLogEntry(
        id: _newId('log'),
        title: title.trim(),
        content: normalized,
        category: category,
        tags: _normalizeTags(tags),
        createdAt: DateTime.now(),
      ),
      ..._logs,
    ];
    _commit();
  }

  void updateLog({
    required String id,
    required String title,
    required String content,
    required DevLogCategory category,
    required List<String> tags,
  }) {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) return;
    _logs = [
      for (final entry in _logs)
        if (entry.id == id)
          entry.copyWith(
            title: title.trim(),
            content: normalizedContent,
            category: category,
            tags: _normalizeTags(tags),
            updatedAt: DateTime.now(),
          )
        else
          entry,
    ];
    _commit();
  }

  void toggleLogPinned(String id) {
    _logs = [
      for (final entry in _logs)
        if (entry.id == id)
          entry.copyWith(isPinned: !entry.isPinned)
        else
          entry,
    ];
    _commit();
  }

  void deleteLog(String id) {
    _logs = _logs.where((entry) => entry.id != id).toList();
    _commit();
  }

  List<String> _normalizeTags(List<String> tags) {
    final normalized = <String>[];
    for (final tag in tags) {
      final value = tag.trim().replaceFirst(RegExp(r'^#+'), '');
      if (value.isNotEmpty && !normalized.contains(value)) {
        normalized.add(value);
      }
    }
    return normalized;
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
    return _repository.save(
      DevNestData(
        tasks: _tasks,
        snippets: _snippets,
        projects: _projects,
        logs: _logs,
        profile: _profile,
      ),
    );
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}

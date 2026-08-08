import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/dev_models.dart';
import 'storage_service.dart';

class AppController extends ChangeNotifier {
  AppController(this._storage);

  final AppStorage _storage;

  List<DevTask> _tasks = const [];
  List<CodeSnippet> _snippets = const [];
  List<DevLogEntry> _logs = const [];
  int _focusMinutes = 25;
  int _completedSessions = 0;
  int _totalFocusMinutes = 0;

  List<DevTask> get tasks => List.unmodifiable(_tasks);
  List<CodeSnippet> get snippets => List.unmodifiable(_snippets);
  List<DevLogEntry> get logs => List.unmodifiable(_logs);
  int get focusMinutes => _focusMinutes;
  int get completedSessions => _completedSessions;
  int get totalFocusMinutes => _totalFocusMinutes;
  int get completedTasks => _tasks.where((task) => task.isDone).length;

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
      _logs = _decodeList(value['logs'], DevLogEntry.fromJson);
      _focusMinutes = value['focusMinutes'] as int? ?? 25;
      _completedSessions = value['completedSessions'] as int? ?? 0;
      _totalFocusMinutes = value['totalFocusMinutes'] as int? ?? 0;
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
      DevTask(id: 'task-2', title: '完成一个 25 分钟无打扰编码'),
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
    _logs = [];
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

  void deleteSnippet(String id) {
    _snippets = _snippets.where((snippet) => snippet.id != id).toList();
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

  void setFocusMinutes(int minutes) {
    _focusMinutes = minutes;
    _commit();
  }

  void completeFocusSession() {
    _completedSessions++;
    _totalFocusMinutes += _focusMinutes;
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
      'logs': _logs.map((entry) => entry.toJson()).toList(),
      'focusMinutes': _focusMinutes,
      'completedSessions': _completedSessions,
      'totalFocusMinutes': _totalFocusMinutes,
    });
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}

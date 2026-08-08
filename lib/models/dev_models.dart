class DevTask {
  const DevTask({required this.id, required this.title, this.isDone = false});

  final String id;
  final String title;
  final bool isDone;

  DevTask copyWith({String? title, bool? isDone}) {
    return DevTask(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'isDone': isDone};

  factory DevTask.fromJson(Map<String, Object?> json) {
    return DevTask(
      id: json['id'] as String,
      title: json['title'] as String,
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}

class CodeSnippet {
  const CodeSnippet({
    required this.id,
    required this.title,
    required this.language,
    required this.code,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String language;
  final String code;
  final bool isFavorite;

  CodeSnippet copyWith({
    String? title,
    String? language,
    String? code,
    bool? isFavorite,
  }) {
    return CodeSnippet(
      id: id,
      title: title ?? this.title,
      language: language ?? this.language,
      code: code ?? this.code,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'language': language,
    'code': code,
    'isFavorite': isFavorite,
  };

  factory CodeSnippet.fromJson(Map<String, Object?> json) {
    return CodeSnippet(
      id: json['id'] as String,
      title: json['title'] as String,
      language: json['language'] as String,
      code: json['code'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

enum ProjectStatus {
  planning,
  building,
  paused,
  completed;

  String get label => switch (this) {
    ProjectStatus.planning => '规划中',
    ProjectStatus.building => '开发中',
    ProjectStatus.paused => '已暂停',
    ProjectStatus.completed => '已完成',
  };

  static ProjectStatus fromJson(Object? value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ProjectStatus.planning,
    );
  }
}

class DevProject {
  const DevProject({
    required this.id,
    required this.name,
    required this.description,
    required this.techStack,
    required this.status,
    required this.progress,
    required this.nextAction,
  });

  final String id;
  final String name;
  final String description;
  final List<String> techStack;
  final ProjectStatus status;
  final int progress;
  final String nextAction;

  DevProject copyWith({
    String? name,
    String? description,
    List<String>? techStack,
    ProjectStatus? status,
    int? progress,
    String? nextAction,
  }) {
    return DevProject(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      techStack: techStack ?? this.techStack,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      nextAction: nextAction ?? this.nextAction,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'techStack': techStack,
    'status': status.name,
    'progress': progress,
    'nextAction': nextAction,
  };

  factory DevProject.fromJson(Map<String, Object?> json) {
    return DevProject(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      techStack: (json['techStack'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      status: ProjectStatus.fromJson(json['status']),
      progress: ((json['progress'] as num?)?.round() ?? 0).clamp(0, 100),
      nextAction: json['nextAction'] as String? ?? '',
    );
  }
}

class DevLogEntry {
  const DevLogEntry({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DevLogEntry.fromJson(Map<String, Object?> json) {
    return DevLogEntry(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class DeveloperProfile {
  const DeveloperProfile({
    required this.name,
    required this.role,
    required this.bio,
  });

  static const initial = DeveloperProfile(
    name: '开发者',
    role: 'Independent Builder',
    bio: '持续构建，持续学习。',
  );

  final String name;
  final String role;
  final String bio;

  DeveloperProfile copyWith({String? name, String? role, String? bio}) {
    return DeveloperProfile(
      name: name ?? this.name,
      role: role ?? this.role,
      bio: bio ?? this.bio,
    );
  }

  Map<String, Object?> toJson() => {'name': name, 'role': role, 'bio': bio};

  factory DeveloperProfile.fromJson(Map<String, Object?> json) {
    String valueOr(Object? value, String fallback) {
      final text = value is String ? value.trim() : '';
      return text.isEmpty ? fallback : text;
    }

    return DeveloperProfile(
      name: valueOr(json['name'], initial.name),
      role: valueOr(json['role'], initial.role),
      bio: valueOr(json['bio'], initial.bio),
    );
  }
}

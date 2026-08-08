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

  CodeSnippet copyWith({bool? isFavorite}) {
    return CodeSnippet(
      id: id,
      title: title,
      language: language,
      code: code,
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

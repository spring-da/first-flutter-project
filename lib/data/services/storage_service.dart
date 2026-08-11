import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 最底层的键值数据源。
///
/// Repository 负责理解业务模型；Storage 只负责读写原始 JSON Map。
abstract interface class AppStorage {
  Future<Map<String, Object?>?> load();

  Future<void> save(Map<String, Object?> value);
}

class SharedPreferencesStorage implements AppStorage {
  static const storageKey = 'devnest_state_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<Map<String, Object?>?> load() async {
    final rawValue = await _preferences.getString(storageKey);
    if (rawValue == null) return null;

    final decoded = jsonDecode(rawValue);
    if (decoded is! Map<String, Object?>) return null;
    return decoded;
  }

  @override
  Future<void> save(Map<String, Object?> value) {
    return _preferences.setString(storageKey, jsonEncode(value));
  }
}

/// 供单元测试使用的内存数据源，不触碰设备文件。
class MemoryStorage implements AppStorage {
  Map<String, Object?>? value;

  @override
  Future<Map<String, Object?>?> load() async => value;

  @override
  Future<void> save(Map<String, Object?> value) async {
    this.value = value;
  }
}

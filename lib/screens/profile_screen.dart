import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../models/dev_models.dart';
import '../theme/app_theme.dart';
import '../widgets/dev_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              sliver: SliverList.list(
                children: [
                  const PageHeader(
                    eyebrow: 'DEVELOPER PROFILE',
                    title: '我的',
                    subtitle: '你的本地开发者身份与 DevNest 数据概览。',
                  ),
                  const SizedBox(height: 24),
                  _ProfileHero(
                    profile: controller.profile,
                    onEdit: () => _showProfileEditor(context),
                  ),
                  const SizedBox(height: 28),
                  const SectionHeader(title: '数据足迹', caption: '所有数据仅保存在当前设备'),
                  const SizedBox(height: 13),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stats = [
                        _StatTile(
                          icon: Icons.rocket_launch_outlined,
                          value: '${controller.projects.length}',
                          label: '项目',
                          color: AppTheme.amber,
                        ),
                        _StatTile(
                          icon: Icons.data_object_rounded,
                          value: '${controller.snippets.length}',
                          label: '代码片段',
                          color: AppTheme.violet,
                        ),
                        _StatTile(
                          icon: Icons.edit_note_rounded,
                          value: '${controller.logs.length}',
                          label: '开发日志',
                          color: AppTheme.cyan,
                        ),
                        _StatTile(
                          icon: Icons.task_alt_rounded,
                          value: '${controller.completedTasks}',
                          label: '已完成任务',
                          color: const Color(0xFF65D995),
                        ),
                      ];
                      final columns = constraints.maxWidth >= 720 ? 4 : 2;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 12) / columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final stat in stats)
                            SizedBox(width: width, height: 126, child: stat),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const SectionHeader(title: '应用信息'),
                  const SizedBox(height: 13),
                  Card(
                    child: Column(
                      children: [
                        const ListTile(
                          leading: _InfoIcon(
                            icon: Icons.shield_outlined,
                            color: AppTheme.cyan,
                          ),
                          title: Text('隐私模式'),
                          subtitle: Text('无账号、无云同步，不上传任何项目内容'),
                        ),
                        const Divider(height: 1, indent: 72),
                        const ListTile(
                          leading: _InfoIcon(
                            icon: Icons.storage_rounded,
                            color: AppTheme.violet,
                          ),
                          title: Text('本地存储'),
                          subtitle: Text('数据由 SharedPreferences 保存在本机'),
                        ),
                        const Divider(height: 1, indent: 72),
                        ListTile(
                          leading: const _InfoIcon(
                            icon: Icons.info_outline_rounded,
                            color: AppTheme.amber,
                          ),
                          title: const Text('DevNest'),
                          subtitle: const Text('Flutter 私人开发者工作台'),
                          trailing: Text(
                            'v1.0.0',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showProfileEditor(BuildContext context) async {
    final draft = await showDialog<_ProfileDraft>(
      context: context,
      builder: (context) => _ProfileEditorDialog(profile: controller.profile),
    );
    if (draft == null) return;
    controller.updateProfile(
      name: draft.name,
      role: draft.role,
      bio: draft.bio,
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.onEdit});

  final DeveloperProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF29234E), Color(0xFF133238)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF3B3761)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFF3B3565),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              profile.name.characters.first.toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.role,
                  style: const TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  profile.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: '编辑资料',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 21),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _ProfileDraft {
  const _ProfileDraft({
    required this.name,
    required this.role,
    required this.bio,
  });

  final String name;
  final String role;
  final String bio;
}

class _ProfileEditorDialog extends StatefulWidget {
  const _ProfileEditorDialog({required this.profile});

  final DeveloperProfile profile;

  @override
  State<_ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends State<_ProfileEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name = widget.profile.name;
  late String _role = widget.profile.role;
  late String _bio = widget.profile.bio;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _ProfileDraft(name: _name.trim(), role: _role.trim(), bio: _bio.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑开发者资料'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _name,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: '称呼'),
                  onChanged: (value) => _name = value,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入称呼' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _role,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '角色',
                    hintText: '例如：Flutter Developer',
                  ),
                  onChanged: (value) => _role = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _bio,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '签名',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (value) => _bio = value,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

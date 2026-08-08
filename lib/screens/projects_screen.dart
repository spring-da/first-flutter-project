import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../models/dev_models.dart';
import '../theme/app_theme.dart';
import '../widgets/dev_widgets.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  ProjectStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final allProjects = widget.controller.projects;
        final projects = allProjects
            .where((project) => _filter == null || project.status == _filter)
            .toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              sliver: SliverList.list(
                children: [
                  PageHeader(
                    eyebrow: 'PROJECT RADAR',
                    title: '项目雷达',
                    subtitle: '看清每个项目的位置，以及真正的下一步。',
                    action: IconButton.filled(
                      tooltip: '新增项目',
                      onPressed: () => _showProjectEditor(context),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _ProjectOverview(projects: allProjects),
                  const SizedBox(height: 22),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('全部 ${allProjects.length}'),
                          selected: _filter == null,
                          onSelected: (_) => setState(() => _filter = null),
                        ),
                        const SizedBox(width: 8),
                        for (final status in ProjectStatus.values) ...[
                          ChoiceChip(
                            avatar: Icon(_statusIcon(status), size: 16),
                            label: Text(
                              '${status.label} ${allProjects.where((item) => item.status == status).length}',
                            ),
                            selected: _filter == status,
                            onSelected: (_) => setState(() => _filter = status),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: _filter?.label ?? '全部项目',
                    caption: '${projects.length} 个项目正在雷达中',
                  ),
                ],
              ),
            ),
            if (projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.radar_rounded,
                  title: _filter == null ? '还没有项目' : '这个状态下没有项目',
                  message: _filter == null
                      ? '创建一个项目，并写下最明确的下一步。'
                      : '切换筛选条件，或者更新一个项目的状态。',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 900 ? 2 : 1;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        mainAxisExtent: 330,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ProjectCard(
                          project: projects[index],
                          onEdit: () => _showProjectEditor(
                            context,
                            project: projects[index],
                          ),
                          onDelete: () =>
                              _confirmDelete(context, projects[index]),
                        ),
                        childCount: projects.length,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showProjectEditor(
    BuildContext context, {
    DevProject? project,
  }) async {
    final draft = await showDialog<_ProjectDraft>(
      context: context,
      builder: (_) => _ProjectEditorDialog(initialProject: project),
    );
    if (draft == null) return;

    if (project == null) {
      widget.controller.addProject(
        name: draft.name,
        description: draft.description,
        techStack: draft.techStack,
        status: draft.status,
        progress: draft.progress,
        nextAction: draft.nextAction,
      );
    } else {
      widget.controller.updateProject(
        id: project.id,
        name: draft.name,
        description: draft.description,
        techStack: draft.techStack,
        status: draft.status,
        progress: draft.progress,
        nextAction: draft.nextAction,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, DevProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('删除项目？'),
        content: Text('「${project.name}」将从项目雷达中移除，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.controller.deleteProject(project.id);
  }
}

class _ProjectOverview extends StatelessWidget {
  const _ProjectOverview({required this.projects});

  final List<DevProject> projects;

  @override
  Widget build(BuildContext context) {
    final building = projects
        .where((project) => project.status == ProjectStatus.building)
        .length;
    final completed = projects
        .where((project) => project.status == ProjectStatus.completed)
        .length;
    final average = projects.isEmpty
        ? 0
        : projects.fold<int>(0, (sum, project) => sum + project.progress) ~/
              projects.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF24204A), Color(0xFF123039)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF393462)),
      ),
      child: Row(
        children: [
          _OverviewMetric.fixed(
            icon: Icons.rocket_launch_outlined,
            color: AppTheme.cyan,
            label: '开发中',
            value: '$building',
          ),
          const _OverviewDivider(),
          _OverviewMetric.fixed(
            icon: Icons.donut_large_rounded,
            color: AppTheme.violet,
            label: '平均进度',
            value: '$average%',
          ),
          const _OverviewDivider(),
          _OverviewMetric.fixed(
            icon: Icons.task_alt_rounded,
            color: AppTheme.amber,
            label: '已完成',
            value: '$completed',
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric.fixed({
    required this.icon,
    required this.color,
    required this.label,
    required this._value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String _value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            _value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onEdit,
    required this.onDelete,
  });

  final DevProject project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(project.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(project.status),
                        color: statusColor,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        project.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: '项目操作',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('编辑'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          '删除',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(project.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              project.description.isEmpty ? '暂未填写项目说明' : project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('进度', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${project.progress}%'),
              ],
            ),
            const SizedBox(height: 7),
            LinearProgressIndicator(
              value: project.progress / 100,
              minHeight: 7,
              borderRadius: BorderRadius.circular(99),
              color: statusColor,
              backgroundColor: AppTheme.surfaceHigh,
            ),
            const SizedBox(height: 17),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.cyan,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '下一步',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          project.nextAction,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final tech in project.techStack.take(4))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.violet.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tech,
                      style: const TextStyle(
                        color: AppTheme.violet,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDraft {
  const _ProjectDraft({
    required this.name,
    required this.description,
    required this.techStack,
    required this.status,
    required this.progress,
    required this.nextAction,
  });

  final String name;
  final String description;
  final List<String> techStack;
  final ProjectStatus status;
  final int progress;
  final String nextAction;
}

class _ProjectEditorDialog extends StatefulWidget {
  const _ProjectEditorDialog({this.initialProject});

  final DevProject? initialProject;

  @override
  State<_ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<_ProjectEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  late String _techStack;
  late String _nextAction;
  late ProjectStatus _status;
  late int _progress;

  bool get _isEditing => widget.initialProject != null;

  @override
  void initState() {
    super.initState();
    final project = widget.initialProject;
    _name = project?.name ?? '';
    _description = project?.description ?? '';
    _techStack = project?.techStack.join(', ') ?? '';
    _nextAction = project?.nextAction ?? '';
    _status = project?.status ?? ProjectStatus.planning;
    _progress = project?.progress ?? 10;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _ProjectDraft(
        name: _name.trim(),
        description: _description.trim(),
        techStack: _techStack
            .split(RegExp('[,，]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        status: _status,
        progress: _status == ProjectStatus.completed ? 100 : _progress,
        nextAction: _nextAction.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑项目' : '新增项目'),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _name,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: '项目名称'),
                  onChanged: (value) => _name = value,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入项目名称' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '项目说明',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (value) => _description = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _techStack,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '技术栈',
                    hintText: 'Flutter, Dart, Firebase',
                  ),
                  onChanged: (value) => _techStack = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProjectStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: '项目状态'),
                  items: [
                    for (final status in ProjectStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _nextAction,
                  decoration: const InputDecoration(labelText: '下一步行动'),
                  onChanged: (value) => _nextAction = value,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '请写下一个明确的下一步'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      '项目进度',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      _status == ProjectStatus.completed
                          ? '100%'
                          : '$_progress%',
                    ),
                  ],
                ),
                Slider(
                  value: (_status == ProjectStatus.completed ? 100 : _progress)
                      .toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$_progress%',
                  onChanged: _status == ProjectStatus.completed
                      ? null
                      : (value) => setState(() => _progress = value.round()),
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
        FilledButton(onPressed: _submit, child: Text(_isEditing ? '更新' : '创建')),
      ],
    );
  }
}

Color _statusColor(ProjectStatus status) => switch (status) {
  ProjectStatus.planning => AppTheme.violet,
  ProjectStatus.building => AppTheme.cyan,
  ProjectStatus.paused => AppTheme.amber,
  ProjectStatus.completed => const Color(0xFF66D17A),
};

IconData _statusIcon(ProjectStatus status) => switch (status) {
  ProjectStatus.planning => Icons.lightbulb_outline_rounded,
  ProjectStatus.building => Icons.rocket_launch_outlined,
  ProjectStatus.paused => Icons.pause_circle_outline_rounded,
  ProjectStatus.completed => Icons.task_alt_rounded,
};

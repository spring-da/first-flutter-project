import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../models/dev_models.dart';
import '../theme/app_theme.dart';
import '../widgets/dev_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.controller,
    required this.onNavigate,
    super.key,
  });

  final AppController controller;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              sliver: SliverList.list(
                children: [
                  const DevNestMark(),
                  const SizedBox(height: 34),
                  PageHeader(
                    eyebrow: _todayLabel(),
                    title: '${_greeting()}，开发者',
                    subtitle: '把复杂留给代码，把清晰留给今天。',
                    action: IconButton.filledTonal(
                      tooltip: '新增任务',
                      onPressed: () => _showAddTaskDialog(context),
                      icon: const Icon(Icons.add_task_rounded),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _FocusHero(
                    focusMinutes: controller.focusMinutes,
                    sessions: controller.completedSessions,
                    onStart: () => onNavigate(1),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final taskMetric = MetricCard(
                        icon: Icons.check_circle_outline_rounded,
                        value:
                            '${controller.completedTasks}/${controller.tasks.length}',
                        label: '今日任务',
                        color: AppTheme.cyan,
                      );
                      final sessionMetric = MetricCard(
                        icon: Icons.local_fire_department_outlined,
                        value: '${controller.completedSessions}',
                        label: '专注回合',
                        color: AppTheme.amber,
                      );
                      final timeMetric = MetricCard(
                        icon: Icons.schedule_rounded,
                        value: '${controller.totalFocusMinutes}m',
                        label: '累计深度工作',
                        color: AppTheme.violet,
                      );

                      if (constraints.maxWidth >= 680) {
                        return SizedBox(
                          height: 168,
                          child: Row(
                            children: [
                              Expanded(child: taskMetric),
                              const SizedBox(width: 12),
                              Expanded(child: sessionMetric),
                              const SizedBox(width: 12),
                              Expanded(child: timeMetric),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          SizedBox(
                            height: 168,
                            child: Row(
                              children: [
                                Expanded(child: taskMetric),
                                const SizedBox(width: 12),
                                Expanded(child: sessionMetric),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(height: 148, child: timeMetric),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  SectionHeader(
                    title: '今日清单',
                    caption: controller.tasks.isEmpty
                        ? '先定义一件值得完成的事'
                        : '完成率 ${(controller.taskProgress * 100).round()}%',
                    action: TextButton.icon(
                      onPressed: () => _showAddTaskDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加'),
                    ),
                  ),
                  const SizedBox(height: 13),
                  if (controller.tasks.isEmpty)
                    const Card(
                      child: EmptyState(
                        icon: Icons.task_alt_rounded,
                        title: '今天还很干净',
                        message: '添加一个小而明确的目标，开始推进。',
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < controller.tasks.length;
                              index++
                            ) ...[
                              _TaskRow(
                                task: controller.tasks[index],
                                onToggle: () => controller.toggleTask(
                                  controller.tasks[index].id,
                                ),
                                onDelete: () => controller.deleteTask(
                                  controller.tasks[index].id,
                                ),
                              ),
                              if (index != controller.tasks.length - 1)
                                const Divider(height: 1, indent: 56),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  const SectionHeader(title: '快速入口', caption: '保持工具近在手边'),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.data_object_rounded,
                          label: '代码片段',
                          color: AppTheme.violet,
                          onTap: () => onNavigate(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.edit_note_rounded,
                          label: '写开发日志',
                          color: AppTheme.cyan,
                          onTap: () => onNavigate(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final textController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加今日任务'),
        content: TextField(
          controller: textController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: '例如：完成登录模块重构'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (title != null) controller.addTask(title);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  String _todayLabel() {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final now = DateTime.now();
    return '${now.month} 月 ${now.day} 日 · ${weekdays[now.weekday - 1]}';
  }
}

class _FocusHero extends StatelessWidget {
  const _FocusHero({
    required this.focusMinutes,
    required this.sessions,
    required this.onStart,
  });

  final int focusMinutes;
  final int sessions;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF25204A), Color(0xFF132D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF393462)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppTheme.amber,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'READY FOR DEEP WORK',
                  style: TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$focusMinutes 分钟专注',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  sessions == 0 ? '今天从第一个回合开始' : '今天已完成 $sessions 个回合',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: '开始专注',
            onPressed: onStart,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final DevTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onToggle,
      leading: Checkbox(value: task.isDone, onChanged: (_) => onToggle()),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.isDone ? TextDecoration.lineThrough : null,
          color: task.isDone
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
      ),
      trailing: IconButton(
        tooltip: '删除任务',
        onPressed: onDelete,
        icon: const Icon(Icons.close_rounded, size: 19),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../models/dev_models.dart';
import '../theme/app_theme.dart';
import '../widgets/dev_widgets.dart';

class DevLogScreen extends StatefulWidget {
  const DevLogScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<DevLogScreen> createState() => _DevLogScreenState();
}

class _DevLogScreenState extends State<DevLogScreen> {
  final _logController = TextEditingController();

  @override
  void dispose() {
    _logController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_logController.text.trim().isEmpty) return;
    widget.controller.addLog(_logController.text);
    _logController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              sliver: SliverList.list(
                children: [
                  const PageHeader(
                    eyebrow: 'DEV LOG',
                    title: '开发日志',
                    subtitle: '写下今天推进了什么，以及为什么。',
                  ),
                  const SizedBox(height: 26),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.terminal_rounded,
                                color: AppTheme.cyan,
                                size: 20,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'QUICK CAPTURE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _logController,
                            minLines: 3,
                            maxLines: 7,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              hintText: '今天解决了什么问题？学到了什么？',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text('记录'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: '时间线',
                    caption: '${widget.controller.logs.length} 条开发记录',
                  ),
                ],
              ),
            ),
            if (widget.controller.logs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: '你的开发故事从这里开始',
                  message: '记录一个解决方案、一次决定，或者一个仍未解决的问题。',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList.separated(
                  itemCount: widget.controller.logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _LogCard(
                    entry: widget.controller.logs[index],
                    isLatest: index == 0,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.entry, required this.isLatest});

  final DevLogEntry entry;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: isLatest ? AppTheme.cyan : AppTheme.violet,
                shape: BoxShape.circle,
                boxShadow: isLatest
                    ? [
                        BoxShadow(
                          color: AppTheme.cyan.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(entry.createdAt),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    entry.content,
                    style: const TextStyle(fontSize: 15, height: 1.55),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final sameDay =
        now.year == date.year && now.month == date.month && now.day == date.day;
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (sameDay) return '今天 $time';
    return '${date.month} 月 ${date.day} 日  $time';
  }
}

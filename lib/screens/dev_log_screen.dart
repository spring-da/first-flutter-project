import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../models/dev_models.dart';
import '../theme/app_theme.dart';
import '../widgets/dev_widgets.dart';

class DevLogScreen extends StatefulWidget {
  const DevLogScreen({
    required this.controller,
    this.embedded = false,
    super.key,
  });

  final AppController controller;
  final bool embedded;

  @override
  State<DevLogScreen> createState() => _DevLogScreenState();
}

class _DevLogScreenState extends State<DevLogScreen> {
  final _searchController = TextEditingController();
  DevLogCategory? _categoryFilter;
  bool _pinnedOnly = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final entries =
            widget.controller.logs.where((entry) {
              final normalizedQuery = _query.toLowerCase();
              final matchesQuery =
                  normalizedQuery.isEmpty ||
                  entry.displayTitle.toLowerCase().contains(normalizedQuery) ||
                  entry.content.toLowerCase().contains(normalizedQuery) ||
                  entry.category.label.toLowerCase().contains(
                    normalizedQuery,
                  ) ||
                  entry.tags.any(
                    (tag) => tag.toLowerCase().contains(normalizedQuery),
                  );
              final matchesCategory =
                  _categoryFilter == null || entry.category == _categoryFilter;
              final matchesPinned = !_pinnedOnly || entry.isPinned;
              return matchesQuery && matchesCategory && matchesPinned;
            }).toList()..sort((a, b) {
              if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
              return b.createdAt.compareTo(a.createdAt);
            });

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                widget.embedded ? 14 : 24,
                20,
                18,
              ),
              sliver: SliverList.list(
                children: [
                  if (!widget.embedded) ...[
                    PageHeader(
                      eyebrow: 'DEV LOG',
                      title: '开发日志',
                      subtitle: '把问题、决策与收获沉淀成可检索的开发记忆。',
                      action: IconButton.filled(
                        tooltip: '新增开发日志',
                        onPressed: () => _showAddPage(context),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                    const SizedBox(height: 26),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '把问题、决策与收获沉淀成可检索的开发记忆。',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          tooltip: '新增开发日志',
                          onPressed: () => _showAddPage(context),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    key: const ValueKey('log-search-input'),
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: InputDecoration(
                      hintText: '搜索标题、正文或标签…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '清空日志搜索',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('全部 ${widget.controller.logs.length}'),
                          selected: _categoryFilter == null && !_pinnedOnly,
                          onSelected: (_) => setState(() {
                            _categoryFilter = null;
                            _pinnedOnly = false;
                          }),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.push_pin_outlined, size: 16),
                          label: const Text('置顶'),
                          selected: _pinnedOnly,
                          onSelected: (value) =>
                              setState(() => _pinnedOnly = value),
                        ),
                        for (final category in DevLogCategory.values) ...[
                          const SizedBox(width: 8),
                          ChoiceChip(
                            key: ValueKey(
                              'log-category-filter-${category.name}',
                            ),
                            avatar: Icon(_categoryIcon(category), size: 16),
                            label: Text(category.label),
                            selected: _categoryFilter == category,
                            onSelected: (selected) => setState(
                              () =>
                                  _categoryFilter = selected ? category : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  SectionHeader(
                    title: '开发时间线',
                    caption: entries.length == widget.controller.logs.length
                        ? '${entries.length} 条开发记录'
                        : '找到 ${entries.length} 条记录',
                  ),
                ],
              ),
            ),
            if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: widget.controller.logs.isEmpty
                      ? Icons.auto_stories_outlined
                      : Icons.manage_search_rounded,
                  title: widget.controller.logs.isEmpty
                      ? '你的开发故事从这里开始'
                      : '没有符合条件的记录',
                  message: widget.controller.logs.isEmpty
                      ? '记录一个解决方案、一次决定，或者一个仍未解决的问题。'
                      : '换个关键词或筛选条件再试试。',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _LogCard(
                    key: ValueKey(entries[index].id),
                    entry: entries[index],
                    onTogglePinned: () =>
                        widget.controller.toggleLogPinned(entries[index].id),
                    onEdit: () => _showEditPage(context, entries[index]),
                    onDelete: () => _confirmDelete(context, entries[index]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPage(BuildContext context) async {
    final draft = await Navigator.of(context).push<_LogDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _LogEditorPage(),
      ),
    );
    if (draft == null) return;
    widget.controller.addLog(
      draft.content,
      title: draft.title,
      category: draft.category,
      tags: draft.tags,
    );
  }

  Future<void> _showEditPage(BuildContext context, DevLogEntry entry) async {
    final draft = await Navigator.of(context).push<_LogDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _LogEditorPage(entry: entry),
      ),
    );
    if (draft == null) return;
    widget.controller.updateLog(
      id: entry.id,
      title: draft.title,
      content: draft.content,
      category: draft.category,
      tags: draft.tags,
    );
  }

  Future<void> _confirmDelete(BuildContext context, DevLogEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
        title: const Text('删除开发日志？'),
        content: Text('「${entry.displayTitle}」将被永久删除，此操作无法撤销。'),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.controller.deleteLog(entry.id);
  }
}

class _LogCard extends StatefulWidget {
  const _LogCard({
    required this.entry,
    required this.onTogglePinned,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final DevLogEntry entry;
  final VoidCallback onTogglePinned;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final categoryColor = _categoryColor(entry.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CategoryBadge(category: entry.category),
                if (entry.isPinned) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: AppTheme.amber,
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(entry.createdAt),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                PopupMenuButton<String>(
                  tooltip: '日志操作',
                  onSelected: (value) {
                    switch (value) {
                      case 'pin':
                        widget.onTogglePinned();
                      case 'edit':
                        widget.onEdit();
                      case 'delete':
                        widget.onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          entry.isPinned
                              ? Icons.push_pin_outlined
                              : Icons.push_pin_rounded,
                        ),
                        title: Text(entry.isPinned ? '取消置顶' : '置顶'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('编辑'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        title: Text('删除'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (entry.title.trim().isNotEmpty) ...[
              Text(
                entry.title.trim(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 9),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                const style = TextStyle(fontSize: 15, height: 1.55);
                final painter = TextPainter(
                  text: TextSpan(text: entry.content, style: style),
                  textDirection: Directionality.of(context),
                  maxLines: 4,
                )..layout(maxWidth: constraints.maxWidth);
                final canExpand = painter.didExceedMaxLines;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.topCenter,
                      child: Text(
                        entry.content,
                        maxLines: _expanded ? null : 4,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                    if (canExpand || _expanded) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        icon: Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.open_in_full_rounded,
                          size: 17,
                        ),
                        label: Text(_expanded ? '收起' : '展开全文'),
                      ),
                    ],
                  ],
                );
              },
            ),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final tag in entry.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (entry.updatedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                '已编辑 ${_formatDate(entry.updatedAt!)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final DevLogCategory category;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_categoryIcon(category), color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogDraft {
  const _LogDraft({
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
  });

  final String title;
  final String content;
  final DevLogCategory category;
  final List<String> tags;
}

class _LogEditorPage extends StatefulWidget {
  const _LogEditorPage({this.entry});

  final DevLogEntry? entry;

  @override
  State<_LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<_LogEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late String _title = widget.entry?.title ?? '';
  late String _content = widget.entry?.content ?? '';
  late String _tags = widget.entry?.tags.join(', ') ?? '';
  late DevLogCategory _category =
      widget.entry?.category ?? DevLogCategory.learning;

  bool get _isEditing => widget.entry != null;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _LogDraft(
        title: _title.trim(),
        content: _content.trim(),
        category: _category,
        tags: _tags
            .split(RegExp(r'[,，\s#]+'))
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '取消',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(_isEditing ? '编辑开发日志' : '新增开发日志'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isEditing ? '完善这条记录的背景、过程和结果。' : '记录一次解决方案、技术决策或新的收获。',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        '记录类型',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in DevLogCategory.values)
                            ChoiceChip(
                              key: ValueKey('log-editor-category-${item.name}'),
                              avatar: Icon(_categoryIcon(item), size: 16),
                              label: Text(item.label),
                              selected: _category == item,
                              onSelected: (_) =>
                                  setState(() => _category = item),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const ValueKey('log-title-input'),
                        initialValue: _title,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '标题（可选）',
                          hintText: '例如：列表卡顿问题复盘',
                        ),
                        onChanged: (value) => _title = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('log-content-input'),
                        initialValue: _content,
                        minLines: 10,
                        maxLines: 22,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: '正文',
                          hintText: '背景、排查过程、方案取舍和最终结果…',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (value) => _content = value,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? '请输入日志正文'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('log-tags-input'),
                        initialValue: _tags,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: '标签（可选）',
                          hintText: 'Flutter, 性能, Android',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                        onChanged: (value) => _tags = value,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(
                    _isEditing ? Icons.save_outlined : Icons.add_rounded,
                  ),
                  label: Text(_isEditing ? '更新日志' : '保存日志'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(DevLogCategory category) => switch (category) {
  DevLogCategory.problem => Icons.build_circle_outlined,
  DevLogCategory.decision => Icons.account_tree_outlined,
  DevLogCategory.learning => Icons.school_outlined,
  DevLogCategory.idea => Icons.lightbulb_outline_rounded,
};

Color _categoryColor(DevLogCategory category) => switch (category) {
  DevLogCategory.problem => AppTheme.cyan,
  DevLogCategory.decision => AppTheme.violet,
  DevLogCategory.learning => const Color(0xFF65D995),
  DevLogCategory.idea => AppTheme.amber,
};

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final sameDay =
      now.year == date.year && now.month == date.month && now.day == date.day;
  final time =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  if (sameDay) return '今天 $time';
  if (now.year == date.year) return '${date.month} 月 ${date.day} 日  $time';
  return '${date.year} 年 ${date.month} 月 ${date.day} 日';
}

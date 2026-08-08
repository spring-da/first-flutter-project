import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_controller.dart';
import '../models/dev_models.dart';
import '../theme/app_theme.dart';
import '../widgets/dev_widgets.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({
    required this.controller,
    this.embedded = false,
    super.key,
  });

  final AppController controller;
  final bool embedded;

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _favoritesOnly = false;

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
        final allSnippets = widget.controller.snippets;
        final favoriteCount = allSnippets
            .where((item) => item.isFavorite)
            .length;
        final normalizedQuery = _query.toLowerCase();
        final snippets =
            allSnippets.where((snippet) {
              final matchesFavorite = !_favoritesOnly || snippet.isFavorite;
              final matchesQuery =
                  snippet.title.toLowerCase().contains(normalizedQuery) ||
                  snippet.language.toLowerCase().contains(normalizedQuery) ||
                  snippet.code.toLowerCase().contains(normalizedQuery);
              return matchesFavorite && matchesQuery;
            }).toList()..sort((a, b) {
              if (a.isFavorite == b.isFavorite) return 0;
              return a.isFavorite ? -1 : 1;
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
                      eyebrow: 'CODE VAULT',
                      title: '代码片段库',
                      subtitle: '收藏那些不值得重复搜索的答案。',
                      action: IconButton.filled(
                        tooltip: '新增片段',
                        onPressed: () => _showAddSnippetDialog(context),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '收藏那些不值得重复搜索的答案。',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          tooltip: '新增片段',
                          onPressed: () => _showAddSnippetDialog(context),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: InputDecoration(
                      hintText: '搜索标题、语言或代码…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '清空搜索',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 9,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.apps_rounded, size: 17),
                        label: Text('全部 ${allSnippets.length}'),
                        selected: !_favoritesOnly,
                        onSelected: (_) =>
                            setState(() => _favoritesOnly = false),
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.star_rounded, size: 17),
                        label: Text('收藏 $favoriteCount'),
                        selected: _favoritesOnly,
                        onSelected: (_) =>
                            setState(() => _favoritesOnly = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: _sectionTitle,
                    caption: '${snippets.length} 个片段',
                  ),
                ],
              ),
            ),
            if (snippets.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: _favoritesOnly
                      ? Icons.star_border_rounded
                      : Icons.code_off_rounded,
                  title: _favoritesOnly ? '还没有收藏片段' : '没有找到代码片段',
                  message: _favoritesOnly
                      ? '点击片段右上角的星标，把常用代码收进这里。'
                      : '换个关键词，或者添加你的第一个片段。',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 900
                        ? 3
                        : constraints.crossAxisExtent >= 580
                        ? 2
                        : 1;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        mainAxisExtent: 270,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _SnippetCard(
                          snippet: snippets[index],
                          onFavorite: () => widget.controller
                              .toggleSnippetFavorite(snippets[index].id),
                          onDelete: () =>
                              _confirmDeleteSnippet(context, snippets[index]),
                          onEdit: () =>
                              _showEditSnippetDialog(context, snippets[index]),
                          onCopy: () => _copySnippet(context, snippets[index]),
                          onExpand: () =>
                              _showSnippetDetails(context, snippets[index].id),
                        ),
                        childCount: snippets.length,
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

  String get _sectionTitle {
    if (_query.isNotEmpty) return '搜索结果';
    if (_favoritesOnly) return '收藏片段';
    return '所有片段';
  }

  Future<void> _copySnippet(BuildContext context, CodeSnippet snippet) async {
    await Clipboard.setData(ClipboardData(text: snippet.code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已复制「${snippet.title}」')));
  }

  Future<void> _showAddSnippetDialog(BuildContext context) async {
    final draft = await showDialog<_SnippetDraft>(
      context: context,
      builder: (_) => const _SnippetEditorDialog(),
    );
    if (draft == null) return;

    widget.controller.addSnippet(
      title: draft.title,
      language: draft.language,
      code: draft.code,
    );
  }

  Future<void> _showEditSnippetDialog(
    BuildContext context,
    CodeSnippet snippet,
  ) async {
    final draft = await showDialog<_SnippetDraft>(
      context: context,
      builder: (_) => _SnippetEditorDialog(initialSnippet: snippet),
    );
    if (draft == null) return;

    widget.controller.updateSnippet(
      id: snippet.id,
      title: draft.title,
      language: draft.language,
      code: draft.code,
    );
  }

  Future<void> _confirmDeleteSnippet(
    BuildContext context,
    CodeSnippet snippet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('删除代码片段？'),
        content: Text('「${snippet.title}」将被永久删除，此操作无法撤销。'),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.controller.deleteSnippet(snippet.id);
  }

  Future<void> _showSnippetDetails(BuildContext context, String snippetId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      builder: (sheetContext) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final snippet = widget.controller.snippets
              .where((item) => item.id == snippetId)
              .firstOrNull;
          if (snippet == null) {
            return const SizedBox.shrink();
          }
          return _SnippetViewer(
            snippet: snippet,
            onFavorite: () =>
                widget.controller.toggleSnippetFavorite(snippet.id),
            onCopy: () => _copySnippet(sheetContext, snippet),
          );
        },
      ),
    );
  }
}

class _SnippetCard extends StatelessWidget {
  const _SnippetCard({
    required this.snippet,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onExpand,
  });

  final CodeSnippet snippet;
  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 15, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LanguageBadge(language: snippet.language),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: snippet.isFavorite ? '取消收藏' : '收藏',
                  onPressed: onFavorite,
                  icon: Icon(
                    snippet.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: snippet.isFavorite ? AppTheme.amber : null,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '更多',
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
            const SizedBox(height: 4),
            Text(
              snippet.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: onExpand,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    snippet.code,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.55,
                      color: Color(0xFFD6DBE8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onExpand,
                    icon: const Icon(Icons.open_in_full_rounded, size: 15),
                    label: const Text('展开全部'),
                  ),
                ),
                IconButton(
                  tooltip: '复制代码',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SnippetViewer extends StatelessWidget {
  const _SnippetViewer({
    required this.snippet,
    required this.onFavorite,
    required this.onCopy,
  });

  final CodeSnippet snippet;
  final VoidCallback onFavorite;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '完整代码',
                          style: TextStyle(
                            color: AppTheme.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          snippet.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: snippet.isFavorite ? '取消收藏' : '收藏',
                    onPressed: onFavorite,
                    icon: Icon(
                      snippet.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: snippet.isFavorite ? AppTheme.amber : null,
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _LanguageBadge(language: snippet.language),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF252B38)),
                    ),
                    child: SelectableText(
                      snippet.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.65,
                        color: Color(0xFFD6DBE8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('复制全部代码'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.violet.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        language,
        style: const TextStyle(
          color: AppTheme.violet,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SnippetDraft {
  const _SnippetDraft({
    required this.title,
    required this.language,
    required this.code,
  });

  final String title;
  final String language;
  final String code;
}

class _SnippetEditorDialog extends StatefulWidget {
  const _SnippetEditorDialog({this.initialSnippet});

  final CodeSnippet? initialSnippet;

  @override
  State<_SnippetEditorDialog> createState() => _SnippetEditorDialogState();
}

class _SnippetEditorDialogState extends State<_SnippetEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _language;
  late String _code;

  bool get _isEditing => widget.initialSnippet != null;

  @override
  void initState() {
    super.initState();
    _title = widget.initialSnippet?.title ?? '';
    _language = widget.initialSnippet?.language ?? '';
    _code = widget.initialSnippet?.code ?? '';
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _SnippetDraft(
        title: _title.trim(),
        language: _language.trim(),
        code: _code.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑代码片段' : '新增代码片段'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _title,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: '标题'),
                  onChanged: (value) => _title = value,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入片段标题' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _language,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '语言',
                    hintText: 'Dart / TypeScript / Shell',
                  ),
                  onChanged: (value) => _language = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _code,
                  minLines: 6,
                  maxLines: 12,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: '代码',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (value) => _code = value,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入代码内容' : null,
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
        FilledButton(onPressed: _submit, child: Text(_isEditing ? '更新' : '保存')),
      ],
    );
  }
}

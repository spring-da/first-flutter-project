import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_controller.dart';
import '../models/dev_models.dart';
import '../theme/app_theme.dart';
import '../widgets/dev_widgets.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchController = TextEditingController();
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
        final snippets =
            widget.controller.snippets.where((snippet) {
              final query = _query.toLowerCase();
              return snippet.title.toLowerCase().contains(query) ||
                  snippet.language.toLowerCase().contains(query) ||
                  snippet.code.toLowerCase().contains(query);
            }).toList()..sort((a, b) {
              if (a.isFavorite == b.isFavorite) return 0;
              return a.isFavorite ? -1 : 1;
            });

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              sliver: SliverList.list(
                children: [
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
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: _query.isEmpty ? '所有片段' : '搜索结果',
                    caption: '${snippets.length} 个片段',
                  ),
                ],
              ),
            ),
            if (snippets.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.code_off_rounded,
                  title: '没有找到代码片段',
                  message: '换个关键词，或者添加你的第一个片段。',
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
                        mainAxisExtent: 250,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _SnippetCard(
                          snippet: snippets[index],
                          onFavorite: () => widget.controller
                              .toggleSnippetFavorite(snippets[index].id),
                          onDelete: () => widget.controller.deleteSnippet(
                            snippets[index].id,
                          ),
                          onCopy: () => _copySnippet(context, snippets[index]),
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

  Future<void> _copySnippet(BuildContext context, CodeSnippet snippet) async {
    await Clipboard.setData(ClipboardData(text: snippet.code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已复制「${snippet.title}」')));
  }

  Future<void> _showAddSnippetDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final languageController = TextEditingController();
    final codeController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增代码片段'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '标题'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: languageController,
                  decoration: const InputDecoration(
                    labelText: '语言',
                    hintText: 'Dart / TypeScript / Shell',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  minLines: 6,
                  maxLines: 12,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: '代码',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      widget.controller.addSnippet(
        title: titleController.text,
        language: languageController.text,
        code: codeController.text,
      );
    }
    titleController.dispose();
    languageController.dispose();
    codeController.dispose();
  }
}

class _SnippetCard extends StatelessWidget {
  const _SnippetCard({
    required this.snippet,
    required this.onFavorite,
    required this.onDelete,
    required this.onCopy,
  });

  final CodeSnippet snippet;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 15, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.violet.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    snippet.language,
                    style: const TextStyle(
                      color: AppTheme.violet,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'delete', child: Text('删除')),
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
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    snippet.code,
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('复制代码'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/dev_widgets.dart';
import 'dev_log_screen.dart';
import 'vault_screen.dart';

class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({
    required this.controller,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final AppController controller;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                eyebrow: 'KNOWLEDGE BASE',
                title: '知识库',
                subtitle: '让可复用的代码与有上下文的思考，各归其位。',
              ),
              const SizedBox(height: 20),
              SegmentedButton<int>(
                key: const ValueKey('knowledge-switcher'),
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.data_object_rounded),
                    label: Text('代码片段'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.edit_note_rounded),
                    label: Text('开发日志'),
                  ),
                ],
                selected: {selectedIndex},
                onSelectionChanged: (selection) => onSelected(selection.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                  side: WidgetStateProperty.resolveWith(
                    (states) => BorderSide(
                      color: states.contains(WidgetState.selected)
                          ? AppTheme.violet
                          : const Color(0xFF343948),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: selectedIndex,
            children: [
              VaultScreen(controller: controller, embedded: true),
              DevLogScreen(controller: controller, embedded: true),
            ],
          ),
        ),
      ],
    );
  }
}

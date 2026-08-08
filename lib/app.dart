import 'package:flutter/material.dart';

import 'core/app_controller.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dev_log_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/vault_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/dev_widgets.dart';

class DevNestApp extends StatelessWidget {
  const DevNestApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: DevNestShell(controller: controller),
    );
  }
}

class DevNestShell extends StatefulWidget {
  const DevNestShell({required this.controller, super.key});

  final AppController controller;

  @override
  State<DevNestShell> createState() => _DevNestShellState();
}

class _DevNestShellState extends State<DevNestShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: '工作台'),
    NavigationDestination(icon: Icon(Icons.timer_outlined), label: '专注'),
    NavigationDestination(icon: Icon(Icons.data_object_rounded), label: '代码库'),
    NavigationDestination(icon: Icon(Icons.edit_note_rounded), label: '日志'),
  ];

  void _navigate(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(controller: widget.controller, onNavigate: _navigate),
      FocusScreen(controller: widget.controller),
      VaultScreen(controller: widget.controller),
      DevLogScreen(controller: widget.controller),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 860;
        final content = IndexedStack(index: _selectedIndex, children: pages);

        if (useRail) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _navigate,
                    extended: constraints.maxWidth >= 1120,
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
                      child: DevNestMark(
                        showName: constraints.maxWidth >= 1120,
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.grid_view_rounded),
                        label: Text('工作台'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.timer_outlined),
                        label: Text('专注'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.data_object_rounded),
                        label: Text('代码库'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.edit_note_rounded),
                        label: Text('日志'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFF252B38)),
                  Expanded(child: content),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(child: content),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _navigate,
            destinations: _destinations,
          ),
        );
      },
    );
  }
}

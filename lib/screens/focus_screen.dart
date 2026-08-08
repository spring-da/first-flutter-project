import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/dev_widgets.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _targetTime;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;

  int get _totalSeconds => widget.controller.focusMinutes * 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = _totalSeconds;
  }

  @override
  void didUpdateWidget(covariant FocusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isRunning &&
        oldWidget.controller.focusMinutes != widget.controller.focusMinutes) {
      _remainingSeconds = _totalSeconds;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning) {
      _syncRemainingTime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) _remainingSeconds = _totalSeconds;
    _targetTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncRemainingTime(),
    );
    setState(() => _isRunning = true);
  }

  void _pauseTimer() {
    _syncRemainingTime();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _targetTime = null;
    });
  }

  void _syncRemainingTime() {
    final target = _targetTime;
    if (target == null) return;
    final remaining = target.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _completeSession();
    } else if (mounted) {
      setState(() => _remainingSeconds = remaining);
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _targetTime = null;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _selectDuration(int minutes) {
    if (_isRunning) return;
    widget.controller.setFocusMinutes(minutes);
    setState(() => _remainingSeconds = minutes * 60);
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    widget.controller.completeFocusSession();
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _targetTime = null;
      _remainingSeconds = _totalSeconds;
    });
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.celebration_rounded,
          color: AppTheme.amber,
          size: 36,
        ),
        title: const Text('专注回合完成'),
        content: const Text('离开屏幕，伸展一下，再决定下一件重要的事。'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = _totalSeconds == 0
        ? 0.0
        : _remainingSeconds / _totalSeconds;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PageHeader(
                    eyebrow: 'FOCUS MODE',
                    title: '深度工作',
                    subtitle: '屏蔽噪音，只保留当前这一件事。',
                  ),
                  const SizedBox(height: 34),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 258,
                            height: 258,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 9,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: AppTheme.surfaceHigh,
                                    color: _isRunning
                                        ? AppTheme.cyan
                                        : AppTheme.violet,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 52,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -2,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _isRunning ? '保持专注' : '准备就绪',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final duration in const [15, 25, 45, 60])
                                ChoiceChip(
                                  label: Text('$duration 分钟'),
                                  selected:
                                      widget.controller.focusMinutes ==
                                      duration,
                                  onSelected: _isRunning
                                      ? null
                                      : (_) => _selectDuration(duration),
                                ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                tooltip: '重置',
                                onPressed: _resetTimer,
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                              const SizedBox(width: 14),
                              FilledButton.icon(
                                onPressed: _toggleTimer,
                                icon: Icon(
                                  _isRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                label: Text(_isRunning ? '暂停' : '开始专注'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                    vertical: 17,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          icon: Icons.bolt_rounded,
                          value: '${widget.controller.completedSessions}',
                          label: '完成回合',
                          color: AppTheme.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          icon: Icons.schedule_rounded,
                          value: '${widget.controller.totalFocusMinutes}m',
                          label: '累计专注',
                          color: AppTheme.cyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

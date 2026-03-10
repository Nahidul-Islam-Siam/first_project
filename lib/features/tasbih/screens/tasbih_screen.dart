import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:first_project/features/tasbih/models/tasbih_models.dart';
import 'package:first_project/features/tasbih/services/tasbih_service.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  static const List<TasbihPreset> _presets = <TasbihPreset>[
    TasbihPreset(id: 'subhanallah', label: 'SubhanAllah', target: 33),
    TasbihPreset(id: 'alhamdulillah', label: 'Alhamdulillah', target: 33),
    TasbihPreset(id: 'allahuakbar', label: 'Allahu Akbar', target: 34),
    TasbihPreset(id: 'astaghfirullah', label: 'Astaghfirullah', target: 100),
  ];

  final TasbihService _service = TasbihService();
  Timer? _ticker;

  TasbihCounterState _state = TasbihCounterState.initial();
  List<TasbihHistoryEntry> _history = const <TasbihHistoryEntry>[];
  DateTime? _sessionStartedAt;
  int _reminderStep = 0;
  String? _uiAlert;
  bool _loading = true;

  TasbihPreset get _selectedPreset => _presets.firstWhere(
    (e) => e.id == _state.regularPresetId,
    orElse: () => _presets.first,
  );

  int get _count => _state.currentCount;
  int get _target => _state.currentTarget;
  String get _label => _state.mode == TasbihMode.regular
      ? _selectedPreset.label
      : 'After Salah - ${_state.selectedPrayer}';

  int get _todayTotal {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return _history
        .where((e) {
          final d = e.finishedAt;
          return DateTime(d.year, d.month, d.day) == day;
        })
        .fold<int>(0, (sum, e) => sum + e.count);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final state = await _service.readState();
    final history = await _service.readHistory();
    if (!mounted) return;
    setState(() {
      _state = state;
      _history = history;
      _loading = false;
    });
  }

  Future<void> _save([TasbihCounterState? next]) async {
    await _service.saveState(next ?? _state);
  }

  Future<void> _setMode(TasbihMode mode) async {
    if (_state.mode == mode) return;
    await _finish(addHistory: _count > 0);
    final next = _state.copyWith(mode: mode);
    setState(() => _state = next);
    await _save(next);
  }

  Future<void> _setPreset(TasbihPreset preset) async {
    if (_state.regularPresetId == preset.id) return;
    await _finish(addHistory: _count > 0);
    final next = _state.copyWith(
      regularPresetId: preset.id,
      regularTarget: preset.target,
      regularCount: 0,
    );
    setState(() => _state = next);
    await _save(next);
  }

  Future<void> _setPrayer(String prayer) async {
    if (_state.selectedPrayer == prayer) return;
    await _finish(addHistory: _count > 0);
    final next = _state.copyWith(selectedPrayer: prayer);
    setState(() => _state = next);
    await _save(next);
  }

  Future<void> _increment() async {
    if (_state.hapticEnabled) await HapticFeedback.selectionClick();
    _sessionStartedAt ??= DateTime.now();
    _uiAlert = null;
    TasbihCounterState next;
    if (_state.mode == TasbihMode.regular) {
      next = _state.copyWith(regularCount: _state.regularCount + 1);
    } else {
      final map = Map<String, int>.from(_state.prayerCounts);
      map[_state.selectedPrayer] = (map[_state.selectedPrayer] ?? 0) + 1;
      next = _state.copyWith(prayerCounts: map);
    }
    final reached =
        _count < next.currentTarget && next.currentCount >= next.currentTarget;
    setState(() => _state = next);
    await _save(next);
    if (!mounted) return;
    if (reached) {
      if (_state.hapticEnabled) await HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Target reached: $_label')));
    }
  }

  Future<void> _undo() async {
    if (_count == 0) return;
    TasbihCounterState next;
    if (_state.mode == TasbihMode.regular) {
      next = _state.copyWith(regularCount: _state.regularCount - 1);
    } else {
      final map = Map<String, int>.from(_state.prayerCounts);
      map[_state.selectedPrayer] = ((map[_state.selectedPrayer] ?? 0) - 1)
          .clamp(0, 100000);
      next = _state.copyWith(prayerCounts: map);
    }
    setState(() => _state = next);
    await _save(next);
  }

  Future<void> _resetActiveCount() async {
    await _finish(addHistory: _count > 0);
  }

  Future<void> _finish({required bool addHistory}) async {
    final beforeCount = _count;
    final beforeTarget = _target;
    final startedAt = _sessionStartedAt;
    final endedAt = DateTime.now();
    final sec = startedAt == null ? 0 : endedAt.difference(startedAt).inSeconds;

    TasbihCounterState next;
    if (_state.mode == TasbihMode.regular) {
      next = _state.copyWith(regularCount: 0);
    } else {
      final map = Map<String, int>.from(_state.prayerCounts);
      map[_state.selectedPrayer] = 0;
      next = _state.copyWith(prayerCounts: map);
    }
    setState(() {
      _state = next;
      _sessionStartedAt = null;
      _reminderStep = 0;
      _uiAlert = null;
    });
    await _save(next);

    if (!addHistory || beforeCount <= 0) return;
    await _service.appendHistory(
      TasbihHistoryEntry(
        finishedAtMillis: endedAt.millisecondsSinceEpoch,
        mode: _state.mode,
        label: _label,
        count: beforeCount,
        target: beforeTarget,
        durationSeconds: sec,
      ),
    );
    final history = await _service.readHistory();
    if (!mounted) return;
    setState(() => _history = history);
  }

  void _tick() {
    if (!mounted || _sessionStartedAt == null) return;
    final reminder = _state.reminderMinutes;
    if (reminder <= 0) return;
    final elapsed = DateTime.now().difference(_sessionStartedAt!);
    final step = elapsed.inSeconds ~/ (reminder * 60);
    if (step <= 0 || step <= _reminderStep) return;
    _reminderStep = step;
    if (_state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _uiAlert = 'Reminder: session is running for ${elapsed.inMinutes} min.';
    });
  }

  Future<void> _openSettings() async {
    final goal = TextEditingController(text: _state.dailyGoal.toString());
    int reminder = _state.reminderMinutes;
    bool haptic = _state.hapticEnabled;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: goal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Daily Goal'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: reminder,
                    decoration: const InputDecoration(labelText: 'Reminder'),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Off')),
                      DropdownMenuItem(value: 5, child: Text('Every 5 min')),
                      DropdownMenuItem(value: 10, child: Text('Every 10 min')),
                      DropdownMenuItem(value: 15, child: Text('Every 15 min')),
                    ],
                    onChanged: (v) => setSheetState(() => reminder = v ?? 0),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vibration'),
                    value: haptic,
                    onChanged: (v) => setSheetState(() => haptic = v),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          final g =
                              int.tryParse(goal.text.trim()) ??
                              _state.dailyGoal;
                          final next = _state.copyWith(
                            dailyGoal: g.clamp(10, 10000),
                            reminderMinutes: reminder,
                            hapticEnabled: haptic,
                          );
                          setState(() => _state = next);
                          await _save(next);
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final progress = _target <= 0 ? 0.0 : (_count / _target).clamp(0.0, 1.0);
    final reminderLabel = _state.reminderMinutes == 0
        ? 'Off'
        : '${_state.reminderMinutes} min';

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            'Tasbih Counter',
                            style: TextStyle(
                              color: glass.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _openSettings,
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    NoorifyGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<TasbihMode>(
                            segments: const [
                              ButtonSegment<TasbihMode>(
                                value: TasbihMode.regular,
                                label: Text('Regular'),
                              ),
                              ButtonSegment<TasbihMode>(
                                value: TasbihMode.afterSalah,
                                label: Text('After Salah'),
                              ),
                            ],
                            selected: <TasbihMode>{_state.mode},
                            onSelectionChanged: (set) => _setMode(set.first),
                          ),
                          const SizedBox(height: 10),
                          if (_state.mode == TasbihMode.regular)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _presets
                                  .map((e) {
                                    return ChoiceChip(
                                      label: Text('${e.label} (${e.target})'),
                                      selected: _state.regularPresetId == e.id,
                                      onSelected: (_) => _setPreset(e),
                                    );
                                  })
                                  .toList(growable: false),
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue: _state.selectedPrayer,
                              decoration: const InputDecoration(
                                labelText: 'Prayer',
                              ),
                              items: afterSalahPrayers
                                  .map(
                                    (p) => DropdownMenuItem<String>(
                                      value: p,
                                      child: Text(
                                        '$p (${_state.countForPrayer(p)})',
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (v) {
                                if (v == null) return;
                                _setPrayer(v);
                              },
                            ),
                          const SizedBox(height: 14),
                          Text(
                            _label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: glass.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _count.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: glass.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 56,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Target: $_target',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: glass.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                          ),
                          if (_uiAlert != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0x22F9A825),
                                border: Border.all(
                                  color: const Color(0x55F9A825),
                                ),
                              ),
                              child: Text(
                                _uiAlert!,
                                style: TextStyle(
                                  color: glass.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Center(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _increment,
                                borderRadius: BorderRadius.circular(999),
                                child: Ink(
                                  width: 148,
                                  height: 148,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [glass.accent, glass.accentSoft],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: glass.glassBorder,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: glass.accent.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.touch_app_rounded,
                                        size: 36,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to Count',
                                        style: TextStyle(
                                          color: glass.isDark
                                              ? Colors.white
                                              : const Color(0xFF073046),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _count > 0 ? _undo : null,
                                  icon: const Icon(Icons.undo_rounded),
                                  label: const Text('Undo'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _count > 0
                                      ? () => _finish(addHistory: true)
                                      : null,
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Finish'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _count > 0
                                      ? _resetActiveCount
                                      : null,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Reset'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    NoorifyGlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today',
                                  style: TextStyle(color: glass.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_todayTotal / ${_state.dailyGoal}',
                                  style: TextStyle(
                                    color: glass.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 34,
                            color: glass.glassBorder,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reminder',
                                  style: TextStyle(color: glass.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reminderLabel,
                                  style: TextStyle(
                                    color: glass.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    NoorifyGlassCard(
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          title: Text(
                            'Recent Sessions',
                            style: TextStyle(
                              color: glass.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          iconColor: glass.textSecondary,
                          collapsedIconColor: glass.textSecondary,
                          children: _history.isEmpty
                              ? <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'No session yet.',
                                        style: TextStyle(
                                          color: glass.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                              : _history
                                    .take(10)
                                    .map((h) {
                                      final t = TimeOfDay.fromDateTime(
                                        h.finishedAt,
                                      ).format(context);
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          '${h.label} - $t',
                                          style: TextStyle(
                                            color: glass.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        trailing: Text(
                                          '${h.count}/${h.target}',
                                          style: TextStyle(color: glass.accent),
                                        ),
                                      );
                                    })
                                    .toList(growable: false),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

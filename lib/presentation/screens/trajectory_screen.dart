import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';
import 'strategy_screens.dart';

class TrajectoryScreen extends StatelessWidget {
  final AppController app;
  final String missionId;

  const TrajectoryScreen(this.app, this.missionId, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trajectory')),
    body: ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final workspace = app.workspace;
        final mission = workspace.record('missions', missionId);
        final skills = workspace
            .records('skills')
            .where((record) => record.ref('mission_id') == missionId)
            .toList();
        final outcomes = workspace
            .records('outcomes')
            .where((record) => record.ref('mission_id') == missionId)
            .toList();
        final metrics = workspace.records('metrics');
        final now = DateTime.now();
        final usage = workspace.usageSummary(now);
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            PageHeading(
              mission?.title ?? 'Mission trajectory',
              'Objective progress from outcomes, verified evidence and manually tracked metrics.',
              action: FilledButton.icon(
                onPressed: () => editStrategyRecord(context, app, 'metrics'),
                icon: const Icon(Icons.add_chart),
                label: const Text('Track metric'),
              ),
            ),
            Section(
              'Last 30 days · product use',
              child: Panel(
                child: Wrap(
                  spacing: 24,
                  runSpacing: 18,
                  children: [
                    _UsageMetric(
                      label: 'Active days',
                      value: '${usage.activeDays}',
                      detail: 'Days with an Obsidian-confirmed session',
                    ),
                    _UsageMetric(
                      label: 'Session completion',
                      value: usage.completionRate == null
                          ? '—'
                          : '${(usage.completionRate! * 100).round()}%',
                      detail:
                          '${usage.completedSessions}/${usage.plannedSessions} planned',
                    ),
                    _UsageMetric(
                      label: 'Weekly reviews',
                      value: '${usage.reviews}/4',
                      detail: 'Saved in the rolling period',
                    ),
                    _UsageMetric(
                      label: 'Evidence / week',
                      value: (usage.evidenceCount / 30 * 7).toStringAsFixed(1),
                      detail: '${usage.evidenceCount} records',
                    ),
                    _UsageMetric(
                      label: 'Retrieval success',
                      value: usage.retrievalSuccess == null
                          ? '—'
                          : '${(usage.retrievalSuccess! * 100).round()}%',
                      detail: usage.averageSearchMs == null
                          ? 'No measured searches'
                          : '${usage.searches} searches · ${usage.averageSearchMs!.toStringAsFixed(0)} ms average',
                    ),
                    _UsageMetric(
                      label: 'Recommendation acceptance',
                      value: usage.recommendationAcceptance == null
                          ? '—'
                          : '${(usage.recommendationAcceptance! * 100).round()}%',
                      detail:
                          '${usage.acceptedRecommendations}/${usage.decidedRecommendations} decisions',
                    ),
                  ],
                ),
              ),
            ),
            Section(
              'Mission outcomes',
              child: outcomes.isEmpty
                  ? const Panel(
                      child: Text(
                        'Add an outcome on the Mission screen to start measuring mission progress.',
                      ),
                    )
                  : Panel(
                      child: Column(
                        children: [
                          for (final outcome in outcomes)
                            _ProgressRow(
                              label: outcome.title,
                              value:
                                  (outcome.number('current_value') /
                                          outcome.number('target', 1))
                                      .clamp(0, 1),
                              detail:
                                  '${outcome.number('current_value')} / ${outcome.number('target')} ${outcome.text('unit')} · ${outcome.text('status')}',
                            ),
                        ],
                      ),
                    ),
            ),
            Section(
              'Capability trajectory',
              child: skills.isEmpty
                  ? const Panel(
                      child: Text(
                        'Add mission skills and verified evidence to see 30-day and 90-day change.',
                      ),
                    )
                  : Panel(
                      child: Column(
                        children: [
                          for (final skill in skills)
                            _SkillTrajectory(
                              title: skill.title,
                              current: workspace.readiness(skill.id),
                              at30Days: workspace.readinessAt(
                                skill.id,
                                now.subtract(const Duration(days: 30)),
                              ),
                              at90Days: workspace.readinessAt(
                                skill.id,
                                now.subtract(const Duration(days: 90)),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            Section(
              'Tracked metrics',
              child: metrics.isEmpty
                  ? const Panel(
                      child: Text(
                        'Track a metric such as interview conversion, revenue, customers or net worth, then add dated snapshots.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final metric in metrics)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MetricCard(app: app, metric: metric),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class _UsageMetric extends StatelessWidget {
  final String label;
  final String value;
  final String detail;

  const _UsageMetric({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final String detail;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${(value * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          minHeight: 8,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 4),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _SkillTrajectory extends StatelessWidget {
  final String title;
  final double current;
  final double at30Days;
  final double at90Days;

  const _SkillTrajectory({
    required this.title,
    required this.current,
    required this.at30Days,
    required this.at90Days,
  });

  String delta(double before) {
    final value = current - before;
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 7),
              LinearProgressIndicator(
                value: current / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 190,
          child: Text(
            '${current.toStringAsFixed(1)}% · 30d ${delta(at30Days)} · 90d ${delta(at90Days)}',
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  final AppController app;
  final StrategyRecord metric;

  const _MetricCard({required this.app, required this.metric});

  @override
  Widget build(BuildContext context) {
    final snapshots =
        app.workspace
            .records('metric_snapshots')
            .where((snapshot) => snapshot.ref('metric_id') == metric.id)
            .toList()
          ..sort(
            (a, b) => (a.data['observed_at'] as int).compareTo(
              b.data['observed_at'] as int,
            ),
          );
    final values = snapshots
        .map((snapshot) => (snapshot.data['value'] as num).toDouble())
        .toList();
    final latest = values.lastOrNull;
    final previous = values.length > 1 ? values[values.length - 2] : null;
    final delta = latest != null && previous != null ? latest - previous : null;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${metric.text('category')} · ${metric.text('direction')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => editStrategyRecord(
                  context,
                  app,
                  'metric_snapshots',
                  initial: {'metric_id': metric.id},
                ),
                child: const Text('Add snapshot'),
              ),
              IconButton(
                tooltip: 'Edit metric',
                onPressed: () =>
                    editStrategyRecord(context, app, 'metrics', record: metric),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (values.isEmpty)
            const Text('No snapshots yet.')
          else
            Row(
              children: [
                SizedBox(
                  width: 180,
                  height: 64,
                  child: CustomPaint(painter: _SparklinePainter(values)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    '${latest.toString()} ${metric.text('unit')}${delta == null ? '' : ' · last change ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}'}\n${snapshots.length} dated snapshot${snapshots.length == 1 ? '' : 's'}',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;

  const _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final color = Colors.teal;
    final grid = Paint()
      ..color = color.withValues(alpha: .14)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      grid,
    );
    if (values.length == 1) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        4,
        Paint()..color = color,
      );
      return;
    }
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final spread = math.max(high - low, 1.0);
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final point = Offset(
        size.width * index / (values.length - 1),
        size.height - ((values[index] - low) / spread * (size.height - 8)) - 4,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values;
}

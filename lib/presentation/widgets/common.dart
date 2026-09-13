import 'package:flutter/material.dart';

String dayLabel(DateTime d) =>
    '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]}, ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.day}';
String timeLabel(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String dateField(DateTime? d) => d == null
    ? ''
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String durationLabel(int seconds) =>
    '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';

class PageHeading extends StatelessWidget {
  final String title, subtitle;
  final Widget? action;
  const PageHeading(this.title, this.subtitle, {this.action, super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: LayoutBuilder(
      builder: (context, constraints) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          SizedBox(
            width: constraints.maxWidth >= 720 && action != null
                ? constraints.maxWidth - 210
                : constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    ),
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({
    required this.child,
    this.padding = const EdgeInsets.all(22),
    super.key,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const Section(this.title, {required this.child, this.trailing, super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, message, action;
  final VoidCallback onAction;
  const EmptyState(
    this.title,
    this.message,
    this.action,
    this.onAction, {
    super.key,
  });
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        Icon(
          Icons.lightbulb_outline,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
}

class Tag extends StatelessWidget {
  final String label;
  const Tag(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class ProgressValue extends StatelessWidget {
  final double? value;
  const ProgressValue(this.value, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value == null
            ? 'Not measured · add a milestone'
            : '${(value! * 100).round()}% · milestone progress',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      if (value != null) ...[
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          minHeight: 5,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    ],
  );
}

Future<void> attempt(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save. $e'),
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }
}

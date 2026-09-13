import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> seedAreas(DatabaseExecutor db) async {
  const areas = {
    'career': ('Career', 0xff558979),
    'income': ('Income', 0xffb08a4d),
    'learning': ('Learning', 0xff7586ac),
    'personal': ('Personal', 0xffaa7a92),
  };
  for (final a in areas.entries) {
    await db.insert('life_areas', {
      'id': a.key,
      'title': a.value.$1,
      'color': a.value.$2,
    });
  }
}

Future<void> seedDemo(DatabaseExecutor db, DateTime now) async {
  await seedAreas(db);
  int ago(int days) =>
      now.subtract(Duration(days: days)).millisecondsSinceEpoch;
  int today(int hour, int minute) => DateTime(
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  ).millisecondsSinceEpoch;
  await db.insert('settings', {'key': 'demo', 'value': 'true'});
  for (final g in [
    (
      'engineering',
      'Increase engineering income',
      'career',
      'Build the capabilities and evidence for better embedded / Linux roles.',
    ),
    (
      'second',
      'Build a second income stream',
      'income',
      'Create a small, useful product with a path to independent income.',
    ),
    (
      'english',
      'Improve English communication',
      'learning',
      'Explain technical decisions clearly and confidently.',
    ),
    (
      'cpp',
      'Become strong in modern C++',
      'career',
      'Write reliable systems software with clear ownership.',
    ),
  ]) {
    await db.insert('goals', {
      'id': g.$1,
      'title': g.$2,
      'life_area_id': g.$3,
      'why': g.$4,
      'description': g.$4,
      'created_at': ago(40),
      'target_at': ago(-90),
    });
  }
  for (final p in [
    (
      'career-upgrade',
      'Career Upgrade',
      'engineering',
      'Compare three embedded Linux roles.',
    ),
    (
      'cpp-path',
      'Modern C++ Path',
      'cpp',
      'Implement a shared_ptr comparison.',
    ),
    (
      'income-lab',
      'Income Lab',
      'second',
      'Build one Excel automation prototype.',
    ),
    (
      'english-project',
      'English Improvement',
      'english',
      'Record a two-minute technical explanation.',
    ),
    (
      'personal-os',
      'Personal OS',
      'second',
      'Validate the session-to-output workflow.',
    ),
  ]) {
    await db.insert('projects', {
      'id': p.$1,
      'title': p.$2,
      'goal_id': p.$3,
      'next_action': p.$4,
      'description': 'A focused initiative: ${p.$4}',
      'created_at': ago(35),
      'start_at': ago(35),
      'target_at': ago(-60),
    });
  }
  for (final m in [
    ('ownership', 'cpp-path', 'Ownership fundamentals', true),
    ('smart', 'cpp-path', 'Working smart pointer examples', false),
    ('prototype', 'income-lab', 'Test an Excel automation offer', false),
    (
      'speaking',
      'english-project',
      'Record five technical explanations',
      false,
    ),
    ('roles', 'career-upgrade', 'Compare target roles', false),
    ('workflow', 'personal-os', 'Complete one real weekly review', false),
  ]) {
    await db.insert('milestones', {
      'id': m.$1,
      'project_id': m.$2,
      'title': m.$3,
      'kind': m.$1 == 'prototype' ? 'experiment' : 'milestone',
      'created_at': ago(30),
      'completed_at': m.$4 ? ago(2) : null,
    });
  }
  for (final s in [
    (
      'today-cpp',
      'Modern C++ — Smart Pointers',
      'cpp-path',
      21,
      0,
      60,
      'Understand ownership and implement one working example.',
      'Read cppreference unique_ptr and compare the existing ownership notes.',
    ),
    (
      'today-english',
      'English Speaking Session',
      'english-project',
      22,
      25,
      60,
      'Record a two-minute explanation of an engineering tradeoff.',
      'Previous speaking notes; a voice recorder.',
    ),
    (
      'today-income',
      'Income Lab — Excel Automation',
      'income-lab',
      23,
      30,
      30,
      'Choose one repetitive spreadsheet workflow to automate.',
      'Review the research and choose one small customer problem.',
    ),
  ]) {
    await db.insert('sessions', {
      'id': s.$1,
      'title': s.$2,
      'project_id': s.$3,
      'planned_start': today(s.$4, s.$5),
      'planned_minutes': s.$6,
      'target': s.$7,
      'input': s.$8,
      'priority': s.$1 == 'today-cpp' ? 1 : 2,
      'created_at': ago(1),
    });
  }
  for (var i = 1; i <= 9; i++) {
    final project = i <= 3
        ? 'income-lab'
        : i.isEven
        ? 'cpp-path'
        : 'english-project';
    final start = DateTime(now.year, now.month, now.day - i, 20);
    final end = start.add(const Duration(minutes: 45));
    await db.insert('sessions', {
      'id': 'past-$i',
      'title': project == 'income-lab'
          ? 'Research automation opportunities'
          : project == 'cpp-path'
          ? 'Ownership practice'
          : 'Technical speaking practice',
      'project_id': project,
      'planned_start': start.millisecondsSinceEpoch,
      'planned_minutes': 60,
      'status': 'DONE',
      'actual_start': start.millisecondsSinceEpoch,
      'actual_end': end.millisecondsSinceEpoch,
      'actual_seconds': 2700,
      'created_at': ago(i + 1),
    });
    await db.insert('focus_intervals', {
      'id': 'interval-$i',
      'session_id': 'past-$i',
      'start_at': start.millisecondsSinceEpoch,
      'end_at': end.millisecondsSinceEpoch,
      'seconds': 2700,
    });
    if (i >= 4) {
      await db.insert('outputs', {
        'id': 'output-$i',
        'title': project == 'cpp-path'
            ? 'Ownership example #$i'
            : 'Technical explanation #$i',
        'type': project == 'cpp-path' ? 'Code sample' : 'Recording',
        'description':
            'Demo evidence of a completed practice session. Replace with your own real output.',
        'project_id': project,
        'session_id': 'past-$i',
        'created_at': end.millisecondsSinceEpoch,
      });
    }
  }
  await db.insert('knowledge', {
    'id': 'ownership-note',
    'title': 'Ownership should be explicit',
    'type': 'Learning',
    'content':
        '## One owner, one responsibility\n\nUse **unique_ptr** when ownership is exclusive.\n\n- Move ownership deliberately.\n- Prefer value semantics when possible.\n- Reach for shared ownership only when the design calls for it.',
    'tags': 'cpp, ownership',
    'project_id': 'cpp-path',
    'session_id': 'past-4',
    'created_at': ago(4),
    'updated_at': ago(4),
  });
  await db.insert('inbox', {
    'id': 'capture-1',
    'title': 'Research freelance Excel automation',
    'kind': 'Project idea',
    'created_at': ago(1),
  });
  await db.insert('inbox', {
    'id': 'capture-2',
    'title': 'Explain RAII with one embedded example',
    'kind': 'Learning topic',
    'created_at': ago(0),
  });
}

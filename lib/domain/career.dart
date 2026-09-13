import 'models.dart';

class ParsedJobDescription {
  final String title;
  final String company;
  final String location;
  final String domain;
  final String seniority;
  final String employmentType;
  final String sourceUrl;
  final int? salaryMin;
  final int? salaryMax;
  final String currency;
  final String description;
  final List<JobRequirementMatch> requirements;

  List<StrategyRecord> get matchedSkills =>
      requirements.map((requirement) => requirement.skill).toList();

  const ParsedJobDescription({
    required this.title,
    required this.company,
    required this.location,
    required this.domain,
    required this.seniority,
    required this.employmentType,
    required this.sourceUrl,
    required this.salaryMin,
    required this.salaryMax,
    required this.currency,
    required this.description,
    required this.requirements,
  });
}

class JobRequirementMatch {
  final StrategyRecord skill;
  final String type;
  final double? yearsRequired;
  final String sourceExcerpt;
  final int confidence;

  const JobRequirementMatch({
    required this.skill,
    required this.type,
    required this.yearsRequired,
    required this.sourceExcerpt,
    required this.confidence,
  });
}

class JobDescriptionParser {
  const JobDescriptionParser();

  List<ParsedJobDescription> parse(
    String input,
    Iterable<StrategyRecord> skills,
  ) {
    final normalized = input.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      throw const FormatException('Paste at least one job description.');
    }
    final chunks = normalized
        .split(RegExp(r'^\s*-{3,}\s*$', multiLine: true))
        .map((chunk) => chunk.trim())
        .where((chunk) => chunk.isNotEmpty)
        .toList();
    if (chunks.length > 50) {
      throw const FormatException(
        'Import at most 50 job descriptions at once.',
      );
    }
    return chunks.map((chunk) {
      final lines = chunk
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      final explicitTitle = _label(lines, 'title');
      final explicitCompany = _label(lines, 'company');
      final title = explicitTitle ?? lines.first;
      final body = chunk.toLowerCase();
      final requirements = <JobRequirementMatch>[];
      for (final skill in skills) {
        final aliases = _aliases(skill.title);
        final matchedAlias = aliases.where((alias) {
          return RegExp(
            '(^|[^a-z0-9+#])${RegExp.escape(alias)}([^a-z0-9+#]|\$)',
          ).hasMatch(body);
        }).firstOrNull;
        if (matchedAlias == null) continue;
        final excerpt = _matchingExcerpt(lines, matchedAlias);
        final lowerExcerpt = excerpt.toLowerCase();
        final preferred = RegExp(
          r'preferred|nice to have|bonus|a plus|advantage',
        ).hasMatch(lowerExcerpt);
        final required = RegExp(
          r'required|requirements?|must|need(?:ed)?|minimum',
        ).hasMatch(lowerExcerpt);
        final years = RegExp(
          r'(\d+(?:\.\d+)?)\s*\+?\s*(?:years?|yrs?)',
        ).firstMatch(lowerExcerpt);
        requirements.add(
          JobRequirementMatch(
            skill: skill,
            type: preferred
                ? 'Preferred'
                : (required ? 'Required' : 'Mentioned'),
            yearsRequired: years == null ? null : double.parse(years.group(1)!),
            sourceExcerpt: excerpt,
            confidence: preferred || required ? 85 : 65,
          ),
        );
      }
      final salary = _salary(_label(lines, 'salary') ?? '');
      return ParsedJobDescription(
        title: title.length <= 140 ? title : '${title.substring(0, 137)}...',
        company: explicitCompany ?? '',
        location: _label(lines, 'location') ?? '',
        domain: _label(lines, 'domain') ?? _domain(body),
        seniority: _label(lines, 'seniority') ?? _seniority(title, body),
        employmentType:
            _label(lines, 'employment') ??
            _label(lines, 'employment type') ??
            _employmentType(body),
        sourceUrl: _label(lines, 'url') ?? _firstUrl(chunk),
        salaryMin: salary.$1,
        salaryMax: salary.$2,
        currency: salary.$3,
        description: chunk,
        requirements: requirements,
      );
    }).toList();
  }

  String _matchingExcerpt(List<String> lines, String alias) => lines.firstWhere(
    (line) => line.toLowerCase().contains(alias),
    orElse: () => alias,
  );

  (int?, int?, String) _salary(String value) {
    final currency =
        RegExp(
          r'\b(USD|EUR|GBP|VND|SGD|AUD|CAD|JPY)\b',
          caseSensitive: false,
        ).firstMatch(value)?.group(1)?.toUpperCase() ??
        '';
    final numbers = RegExp(r'\d[\d,.]*')
        .allMatches(value)
        .map(
          (match) =>
              int.tryParse(match.group(0)!.replaceAll(RegExp(r'[,\.]'), '')),
        )
        .whereType<int>()
        .toList();
    if (numbers.isEmpty) return (null, null, currency);
    return (numbers.first, numbers.length > 1 ? numbers[1] : null, currency);
  }

  String _domain(String body) {
    const domains = {
      'Automotive': ['automotive', 'adas', 'vehicle', 'autosar'],
      'Embedded': ['embedded', 'firmware', 'microcontroller'],
      'Cloud': ['cloud', 'kubernetes', 'distributed system'],
      'Fintech': ['fintech', 'banking', 'payments'],
      'Security': ['security', 'cybersecurity', 'cryptography'],
      'AI': ['machine learning', 'artificial intelligence', ' llm'],
      'Gaming': ['gaming', 'game engine'],
    };
    for (final entry in domains.entries) {
      if (entry.value.any(body.contains)) return entry.key;
    }
    return '';
  }

  String _seniority(String title, String body) {
    final text = '${title.toLowerCase()} $body';
    if (RegExp(r'\b(principal|staff)\b').hasMatch(text)) return 'Staff+';
    if (RegExp(r'\b(senior|lead)\b').hasMatch(text)) return 'Senior';
    if (RegExp(r'\b(junior|entry.level|graduate)\b').hasMatch(text)) {
      return 'Junior';
    }
    return '';
  }

  String _employmentType(String body) {
    if (body.contains('part-time') || body.contains('part time')) {
      return 'Part-time';
    }
    if (body.contains('contract')) return 'Contract';
    if (body.contains('internship') || body.contains('intern ')) {
      return 'Internship';
    }
    if (body.contains('full-time') || body.contains('full time')) {
      return 'Full-time';
    }
    return '';
  }

  String _firstUrl(String text) =>
      RegExp(r'https?://\S+').firstMatch(text)?.group(0) ?? '';

  String? _label(List<String> lines, String label) {
    final prefix = '$label:';
    for (final line in lines) {
      if (line.toLowerCase().startsWith(prefix)) {
        final value = line.substring(prefix.length).trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  Set<String> _aliases(String title) {
    final lower = title.toLowerCase().trim();
    final aliases = <String>{lower};
    aliases.addAll(
      lower
          .split(RegExp(r'\s*(?:/|,|\||×|\band\b)\s*'))
          .map((part) => part.trim())
          .where((part) => part.length >= 2),
    );
    if (lower.contains('modern c++')) aliases.add('c++');
    if (lower.contains('systems programming')) {
      aliases.add('system programming');
    }
    if (lower.contains('job pipeline')) {
      aliases.addAll(['application', 'recruiter']);
    }
    return aliases;
  }
}

String jobDescriptionFingerprint(String description) {
  final normalized = description
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  var hash = 0xcbf29ce484222325;
  for (final unit in normalized.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

class SkillDemand {
  final StrategyRecord skill;
  final int jobCount;
  final int totalJobs;
  final double readiness;

  const SkillDemand(this.skill, this.jobCount, this.totalJobs, this.readiness);

  double get demand => totalJobs == 0 ? 0 : jobCount / totalJobs;
  double get priorityGap => demand * (100 - readiness);
}

List<SkillDemand> skillDemandForMission(Workspace workspace, String missionId) {
  final jobs = workspace
      .records('jobs')
      .where((job) => job.ref('mission_id') == missionId)
      .toList();
  final requirements = workspace.records('job_requirements');
  final result = <SkillDemand>[];
  for (final skill
      in workspace
          .records('skills')
          .where((skill) => skill.ref('mission_id') == missionId)) {
    final count = requirements
        .where(
          (requirement) =>
              requirement.ref('skill_id') == skill.id &&
              jobs.any((job) => job.id == requirement.ref('job_id')),
        )
        .map((requirement) => requirement.ref('job_id'))
        .toSet()
        .length;
    result.add(
      SkillDemand(skill, count, jobs.length, workspace.readiness(skill.id)),
    );
  }
  result.sort((a, b) => b.priorityGap.compareTo(a.priorityGap));
  return result;
}

class PrioritySuggestion {
  final String title;
  final String reason;
  final double confidence;
  final String? skillId;

  const PrioritySuggestion(
    this.title,
    this.reason,
    this.confidence, {
    this.skillId,
  });
}

List<PrioritySuggestion> nextWeekPrioritySuggestions(
  Workspace workspace,
  String missionId,
) {
  final result = <PrioritySuggestion>[];
  final interviewPriorities =
      workspace
          .records('learning_priorities')
          .where(
            (priority) =>
                priority.ref('mission_id') == missionId &&
                priority.text('status') == 'Active',
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final priority in interviewPriorities.take(3)) {
    result.add(
      PrioritySuggestion(
        priority.title,
        priority.text('reason'),
        .9,
        skillId: priority.ref('skill_id'),
      ),
    );
  }
  for (final demand in skillDemandForMission(workspace, missionId)) {
    if (result.length >= 5 ||
        demand.jobCount == 0 ||
        demand.readiness >= 70 ||
        result.any((item) => item.title.contains(demand.skill.title))) {
      continue;
    }
    result.add(
      PrioritySuggestion(
        'Improve ${demand.skill.title}',
        'Appears in ${demand.jobCount}/${demand.totalJobs} saved jobs; current verified readiness is ${demand.readiness.round()}%.',
        (.45 + demand.demand * .45).clamp(0, .9),
        skillId: demand.skill.id,
      ),
    );
  }
  return result;
}

import 'models.dart';

class KnowledgeMetadataSuggestion {
  final String summary;
  final List<String> tags;
  final String? skillId;
  final String? projectId;
  final String? missionId;

  const KnowledgeMetadataSuggestion({
    required this.summary,
    required this.tags,
    this.skillId,
    this.projectId,
    this.missionId,
  });
}

KnowledgeMetadataSuggestion suggestKnowledgeMetadata(
  String text,
  Workspace workspace,
) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final sentences = normalized
      .split(RegExp(r'(?<=[.!?])\s+'))
      .where((sentence) => sentence.trim().isNotEmpty)
      .take(3)
      .join(' ');
  final summarySource = sentences.isEmpty ? normalized : sentences;
  final summary = summarySource.length <= 500
      ? summarySource
      : '${summarySource.substring(0, 497).trimRight()}...';
  final lower = normalized.toLowerCase();
  final matchedSkills =
      workspace
          .records('skills')
          .where((skill) => _containsPhrase(lower, skill.title.toLowerCase()))
          .toList()
        ..sort((a, b) => b.title.length.compareTo(a.title.length));
  final matchedProjects =
      workspace.projects
          .where(
            (project) => _containsPhrase(lower, project.title.toLowerCase()),
          )
          .toList()
        ..sort((a, b) => b.title.length.compareTo(a.title.length));
  final frequencies = <String, int>{};
  for (final match in RegExp(
    r'[a-zA-Z][a-zA-Z0-9+#.-]{2,}',
  ).allMatches(lower)) {
    final word = match.group(0)!;
    if (!_stopWords.contains(word)) {
      frequencies[word] = (frequencies[word] ?? 0) + 1;
    }
  }
  final keywords = frequencies.entries.toList()
    ..sort((a, b) {
      final count = b.value.compareTo(a.value);
      return count == 0 ? a.key.compareTo(b.key) : count;
    });
  final tags = <String>{
    ...matchedSkills.take(3).map((skill) => skill.title),
    ...keywords.take(5).map((entry) => entry.key),
  }.take(6).toList();
  final skill = matchedSkills.firstOrNull;
  return KnowledgeMetadataSuggestion(
    summary: summary,
    tags: tags,
    skillId: skill?.id,
    projectId: matchedProjects.firstOrNull?.id,
    missionId: skill?.ref('mission_id'),
  );
}

bool _containsPhrase(String source, String phrase) {
  final value = phrase.trim();
  if (value.length < 2) return false;
  return RegExp(
    '(^|[^a-z0-9+#])${RegExp.escape(value)}([^a-z0-9+#]|\$)',
  ).hasMatch(source);
}

const _stopWords = <String>{
  'about',
  'after',
  'also',
  'and',
  'are',
  'been',
  'before',
  'between',
  'can',
  'could',
  'for',
  'from',
  'have',
  'into',
  'more',
  'not',
  'only',
  'that',
  'the',
  'their',
  'then',
  'this',
  'through',
  'using',
  'was',
  'were',
  'which',
  'will',
  'with',
  'your',
};

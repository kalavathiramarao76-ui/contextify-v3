import 'dart:convert';

class RedFlag {
  final String text;
  final String reason;
  final String severity;
  final String type;

  const RedFlag({
    required this.text,
    required this.reason,
    required this.severity,
    required this.type,
  });

  factory RedFlag.fromJson(Map<String, dynamic> json) {
    return RedFlag(
      text: json['text'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      type: json['type'] as String? ?? 'ambiguity',
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'reason': reason,
        'severity': severity,
        'type': type,
      };
}

class AnalysisResult {
  final String summary;
  final String riskLevel;
  final int manipulationScore;
  final List<RedFlag> flags;
  final List<String> keyPoints;
  final List<String> hiddenMeanings;
  final String toneAnalysis;
  final String suggestedResponse;
  final String originalText;
  final DateTime timestamp;

  const AnalysisResult({
    required this.summary,
    required this.riskLevel,
    required this.manipulationScore,
    required this.flags,
    required this.keyPoints,
    required this.hiddenMeanings,
    required this.toneAnalysis,
    required this.suggestedResponse,
    required this.originalText,
    required this.timestamp,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json,
      {String originalText = ''}) {
    return AnalysisResult(
      summary: json['summary'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? 'safe',
      manipulationScore: (json['manipulationScore'] as num?)?.toInt() ?? 0,
      flags: (json['flags'] as List<dynamic>?)
              ?.map((e) => RedFlag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      keyPoints: (json['keyPoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hiddenMeanings: (json['hiddenMeanings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      toneAnalysis: json['toneAnalysis'] as String? ?? '',
      suggestedResponse: json['suggestedResponse'] as String? ?? '',
      originalText: json['originalText'] as String? ?? originalText,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'riskLevel': riskLevel,
        'manipulationScore': manipulationScore,
        'flags': flags.map((f) => f.toJson()).toList(),
        'keyPoints': keyPoints,
        'hiddenMeanings': hiddenMeanings,
        'toneAnalysis': toneAnalysis,
        'suggestedResponse': suggestedResponse,
        'originalText': originalText,
        'timestamp': timestamp.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory AnalysisResult.fromJsonString(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return AnalysisResult.fromJson(map);
  }

  String toShareText() {
    final buffer = StringBuffer();
    buffer.writeln('Contextify Analysis');
    buffer.writeln('==============================');
    buffer.writeln();
    buffer.writeln('Risk Level: ${riskLevel.toUpperCase()}');
    buffer.writeln('Manipulation Score: $manipulationScore/100');
    buffer.writeln();
    buffer.writeln('Summary:');
    buffer.writeln(summary);
    buffer.writeln();
    if (keyPoints.isNotEmpty) {
      buffer.writeln('Key Points:');
      for (int i = 0; i < keyPoints.length; i++) {
        buffer.writeln('  ${i + 1}. ${keyPoints[i]}');
      }
      buffer.writeln();
    }
    if (flags.isNotEmpty) {
      buffer.writeln('Red Flags: ${flags.length} found');
      for (final flag in flags) {
        buffer.writeln('  - [${flag.severity.toUpperCase()}] ${flag.text}');
      }
      buffer.writeln();
    }
    if (hiddenMeanings.isNotEmpty) {
      buffer.writeln('Hidden Meanings:');
      for (final meaning in hiddenMeanings) {
        buffer.writeln('  - $meaning');
      }
      buffer.writeln();
    }
    buffer.writeln('Tone: $toneAnalysis');
    if (suggestedResponse.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Suggested Response:');
      buffer.writeln(suggestedResponse);
    }
    buffer.writeln();
    buffer.writeln('Analyzed with Contextify');
    return buffer.toString();
  }

  String get textPreview {
    if (originalText.length <= 80) return originalText;
    return '${originalText.substring(0, 80)}...';
  }

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

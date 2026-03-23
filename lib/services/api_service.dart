import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String _endpoint =
      'https://contextify-v2-api.vercel.app/api/analyze';
  static const String _model = 'gpt-oss:120b';
  static const double _temperature = 0.3;
  static const int _maxTokens = 2048;
  static const Duration _timeout = Duration(seconds: 60);

  static const String _systemPrompt =
      'You are Contextify AI. Analyze the given text thoroughly and return ONLY valid JSON (no markdown, no code fences). The JSON must have this exact structure:\n'
      '{\n'
      '  "summary": "A clear, plain-English explanation of what this text actually says and means.",\n'
      '  "riskLevel": "safe|caution|warning|danger",\n'
      '  "manipulationScore": 0-100,\n'
      '  "flags": [{"text":"...","reason":"...","severity":"low|medium|high|critical","type":"manipulation|legal|financial|emotional|deception|pressure|ambiguity"}],\n'
      '  "keyPoints": ["..."],\n'
      '  "hiddenMeanings": ["..."],\n'
      '  "toneAnalysis": "...",\n'
      '  "suggestedResponse": "..."\n'
      '}';

  static Future<AnalysisResult> analyzeText(String text) async {
    if (text.trim().isEmpty) {
      throw const ApiException('Please enter some text to analyze.');
    }

    final body = jsonEncode({
      'model': _model,
      'temperature': _temperature,
      'max_tokens': _maxTokens,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': text},
      ],
    });

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'Server error (${response.statusCode}). Please try again.',
        );
      }

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = responseJson['choices'] as List<dynamic>?;

      if (choices == null || choices.isEmpty) {
        throw const ApiException('No response from AI.');
      }

      final message = choices[0]['message'] as Map<String, dynamic>;
      final content = message['content'] as String;

      final parsedJson = _parseJsonResponse(content);
      return AnalysisResult.fromJson(parsedJson, originalText: text);
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw const ApiException(
            'Request timed out. Please check your connection and try again.');
      }
      throw ApiException('Analysis failed: $e');
    }
  }

  static Map<String, dynamic> _parseJsonResponse(String content) {
    String cleaned = content.trim();

    // Remove markdown code fences if present
    final fencePattern = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?\s*```');
    final match = fencePattern.firstMatch(cleaned);
    if (match != null) {
      cleaned = match.group(1)!.trim();
    }

    // Try parsing directly
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      // Try to find JSON object in the string
      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonStr = cleaned.substring(jsonStart, jsonEnd + 1);
        try {
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (_) {
          throw const ApiException('Failed to parse AI response.');
        }
      }
      throw const ApiException('AI response did not contain valid JSON.');
    }
  }
}

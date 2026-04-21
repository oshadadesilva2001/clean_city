import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class GroqService {
  static Future<Map<String, String>> classifyReport(
      String description) async {
    final body = jsonEncode({
      'model': kGroqModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a waste classification assistant. Return only valid JSON.',
        },
        {
          'role': 'user',
          'content':
              'Classify this litter report into a category and priority. '
              'Category must be exactly one of: Plastic, Organic, Hazardous, '
              'Construction, Electronic, Mixed. '
              'Priority must be exactly one of: Low, Medium, High, Urgent. '
              'Return JSON only: {"category":"...","priority":"..."}. '
              'Report: "$description"',
        },
      ],
      'response_format': {'type': 'json_object'},
      'max_tokens': 60,
      'temperature': 0.1,
    });

    final response = await http.post(
      Uri.parse(kGroqBaseUrl),
      headers: {
        'Authorization': 'Bearer $kGroqApiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Groq classifyReport failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        decoded['choices'][0]['message']['content'] as String;
    final result = jsonDecode(content) as Map<String, dynamic>;
    return {
      'category': result['category'] as String? ?? 'Mixed',
      'priority': result['priority'] as String? ?? 'Medium',
    };
  }

  static Future<String> suggestAssignmentNote(String description) async {
    final body = jsonEncode({
      'model': kGroqModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You write brief, clear field instructions for sanitation workers.',
        },
        {
          'role': 'user',
          'content':
              'Write a 1–2 sentence instruction for a sanitation worker to '
              'clean up this litter. Be direct and specific. '
              'Return only the instruction text, no quotes or preamble. '
              'Report: "$description"',
        },
      ],
      'max_tokens': 80,
      'temperature': 0.3,
    });

    final response = await http.post(
      Uri.parse(kGroqBaseUrl),
      headers: {
        'Authorization': 'Bearer $kGroqApiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Groq suggestAssignmentNote failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['choices'][0]['message']['content'] as String).trim();
  }

  static Future<String> generateDigest({
    required int total,
    required int pending,
    required int assigned,
    required int completed,
  }) async {
    final body = jsonEncode({
      'model': kGroqModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You write concise situational summaries for city waste management authorities.',
        },
        {
          'role': 'user',
          'content':
              'Write a 2-sentence situational summary based on these report stats: '
              'Total: $total, Pending: $pending, Assigned: $assigned, Completed: $completed. '
              'Focus on actionable insights. Return only the summary text.',
        },
      ],
      'max_tokens': 120,
      'temperature': 0.4,
    });

    final response = await http.post(
      Uri.parse(kGroqBaseUrl),
      headers: {
        'Authorization': 'Bearer $kGroqApiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Groq generateDigest failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['choices'][0]['message']['content'] as String).trim();
  }

  static Future<String> chat(List<Map<String, String>> messages) async {
    final allMessages = [
      {
        'role': 'system',
        'content':
            'You are a helpful waste management assistant for the Clean City app. '
            'You help citizens with proper waste disposal, recycling guidance, '
            'and information about local waste regulations. Be concise and friendly.',
      },
      ...messages,
    ];

    final body = jsonEncode({
      'model': kGroqModel,
      'messages': allMessages,
      'max_tokens': 400,
      'temperature': 0.6,
    });

    final response = await http.post(
      Uri.parse(kGroqBaseUrl),
      headers: {
        'Authorization': 'Bearer $kGroqApiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Groq chat failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['choices'][0]['message']['content'] as String).trim();
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EdgeFunctionService {
  final _supabase = Supabase.instance.client;

  Future<List<String>> generateQuestions({
    required String area,
    required String level,
    String? jobDescription,
    required int count,
  }) async {
    final response = await _supabase.functions.invoke(
      'generate-questions',
      body: {
        'area': area,
        'level': level,
        // ignore: use_null_aware_elements
        if (jobDescription != null) 'job_description': jobDescription,
        'count': count,
      },
    );
    debugPrint('[EdgeFn] generate-questions raw response: ${response.data}');
    final data = response.data as Map<String, dynamic>;
    if (data.containsKey('error')) {
      throw Exception('generate-questions error: ${data['error']}');
    }
    return List<String>.from(data['questions'] as List);
  }

  Future<String> transcribeAudio(Uint8List audioBytes) async {
    final response = await _supabase.functions.invoke(
      'transcribe',
      body: {
        'audio': base64Encode(audioBytes),
        'mime_type': 'audio/m4a',
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['transcript'] as String;
  }

  Future<Map<String, dynamic>> evaluateAnswer({
    required String question,
    required String answer,
    required String area,
    required String level,
  }) async {
    final response = await _supabase.functions.invoke(
      'evaluate-answer',
      body: {
        'question': question,
        'answer': answer,
        'area': area,
        'level': level,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> generateReport({
    required String interviewId,
    required List<Map<String, dynamic>> questions,
    required String area,
    required String level,
  }) async {
    final response = await _supabase.functions.invoke(
      'generate-report',
      body: {
        'interview_id': interviewId,
        'questions': questions,
        'area': area,
        'level': level,
      },
    );
    if (response.data == null) {
      throw Exception('generate-report retornou resposta vazia');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data.containsKey('error')) {
      throw Exception('generate-report error: ${data['error']}');
    }
    return data;
  }
}

final edgeFunctionServiceProvider = Provider<EdgeFunctionService>((ref) {
  return EdgeFunctionService();
});

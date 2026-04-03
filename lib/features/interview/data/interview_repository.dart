import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:axion/features/interview/models/interview_models.dart';

final interviewRepositoryProvider = Provider<InterviewRepository>((ref) {
  return InterviewRepository();
});

class InterviewRepository {
  final _db = Supabase.instance.client;

  /// Returns the user's interview history (without nested questions/plan).
  Future<List<InterviewSession>> getHistory(String userId) async {
    final data = await _db
        .from('interviews')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => InterviewSession.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Returns a single session with its questions and action plan.
  Future<InterviewSession?> getSessionWithDetails(String sessionId) async {
    final data = await _db
        .from('interviews')
        .select('*, interview_questions(*), action_plans(*)')
        .eq('id', sessionId)
        .maybeSingle();

    if (data == null) return null;
    return InterviewSession.fromJson(data);
  }

  /// Persists a completed session to Supabase.
  Future<void> saveSession(InterviewSession session) async {
    await _db.from('interviews').upsert(session.toJson());

    if (session.questions.isNotEmpty) {
      await _db.from('interview_questions').upsert(
        session.questions.map((q) => q.toJson()).toList(),
      );
    }

    if (session.actionPlan != null) {
      await _db.from('action_plans').upsert(session.actionPlan!.toJson());
    }
  }
}

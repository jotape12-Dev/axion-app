import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:axion/core/constants/app_constants.dart';
import 'package:axion/features/interview/models/interview_models.dart';

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  StreamSubscription? _authSubscription;
  final _db = Supabase.instance.client;

  UserProfileNotifier() : super(null) {
    _init();
  }

  void _init() {
    // Load profile if there's already a session
    final session = _db.auth.currentSession;
    if (session != null) {
      _loadProfile(session.user.id, session.user.email ?? '');
    }

    // React to future auth state changes
    _authSubscription = _db.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        final user = data.session?.user;
        if (user != null) {
          _loadProfile(user.id, user.email ?? '');
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = null;
      }
    });
  }

  Future<void> _loadProfile(String userId, String email) async {
    try {
      final data = await _db
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        state = UserProfile.fromJson(data);
      } else {
        // New user — minimal profile, will complete onboarding
        state = UserProfile(
          id: userId,
          email: email,
          onboardingCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } catch (_) {
      // DB error (table missing, network, etc.) — create in-memory fallback
      // so the app still works and redirects to profile-setup.
      state = UserProfile(
        id: userId,
        email: email,
        onboardingCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    state = updated;
    try {
      await _db.from('profiles').upsert(updated.toJson());
    } catch (_) {}
  }

  Future<void> completeOnboarding({
    required String displayName,
    required InterviewArea area,
    required SeniorityLevel level,
  }) async {
    if (state == null) return;
    final updated = state!.copyWith(
      displayName: displayName,
      preferredArea: area,
      seniorityLevel: level,
      onboardingCompleted: true,
      updatedAt: DateTime.now(),
    );
    state = updated;
    try {
      await _db.from('profiles').upsert(updated.toJson());
    } catch (_) {}
  }

  Future<void> signOut() async {
    await _db.auth.signOut();
    state = null;
  }

  Future<void> deleteAccount() async {
    try {
      await _db.rpc('delete_user');
      await signOut();
    } catch (_) {
      // Caso ocorra um erro ao tentar deletar usando a RPC
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/cloud_functions_client.dart';
import 'moderation_result.dart'
    show ModerationRejectedException, MediaReviewUnavailableException;

/// Submits community stories through the trusted Cloud Function.
Future<Map<String, dynamic>> submitCommunityStory(
  Map<String, dynamic> payload, {
  FirebaseAuth? auth,
}) async {
  final user = (auth ?? FirebaseAuth.instance).currentUser;
  if (user == null) throw StateError('Not signed in');
  final response = await CloudFunctionsClient.instance.post(
    '/submitCommunity',
    body: {'action': 'story', ...payload},
    timeout: const Duration(seconds: 32),
  );

  Map<String, dynamic> body = const {};
  if (response.body.isNotEmpty) {
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      debugPrint('submitCommunityStory: invalid JSON response');
    }
  }
  if (response.statusCode == 200) return body;

  final code = body['error'] as String? ?? '';
  final message = body['message'] as String? ?? 'Could not publish story.';
  if (code == 'media_review_unavailable') {
    throw const MediaReviewUnavailableException();
  }
  if (code == 'content_rejected' ||
      code == 'rate_limited' ||
      code == 'duplicate_content') {
    // Surface the moderation reason instead of a generic error, so a rejected
    // story image explains itself the same way a rejected post does.
    throw ModerationRejectedException(message);
  }
  throw StateError(message);
}

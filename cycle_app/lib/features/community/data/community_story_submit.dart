import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/cloud_functions_client.dart';

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

  final message = body['message'] as String? ?? 'Could not publish story.';
  throw StateError(message);
}

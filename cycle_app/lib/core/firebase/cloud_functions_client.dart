import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

/// Shared HTTP client for Cloud Functions with Auth + App Check headers.
class CloudFunctionsClient {
  CloudFunctionsClient({
    FirebaseAuth? auth,
    http.Client? httpClient,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _http = httpClient ?? http.Client();

  final FirebaseAuth _auth;
  final http.Client _http;

  static final CloudFunctionsClient instance = CloudFunctionsClient();

  static String get baseUrl => AppSecrets.cloudFunctionsUrl;

  Future<Map<String, String>> buildHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Fetch the auth and App Check tokens together instead of serially. The
    // App Check call is bounded by a short timeout: while App Check stays in
    // monitoring mode the token is optional, so a slow or failing attestation
    // (sideloaded build, or Play Integrity/debug token not set up yet) must
    // never stall the request for seconds on every post/comment.
    final authFuture = requireAuth
        ? (_auth.currentUser?.getIdToken() ?? Future<String?>.value())
        : Future<String?>.value();
    final appCheckFuture = FirebaseAppCheck.instance
        .getToken()
        .timeout(const Duration(seconds: 2), onTimeout: () => null)
        .catchError((Object _) => null);

    final tokens = await Future.wait([authFuture, appCheckFuture]);

    final authToken = tokens[0];
    if (requireAuth && authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    final appCheckToken = tokens[1];
    if (appCheckToken != null && appCheckToken.isNotEmpty) {
      headers['X-Firebase-AppCheck'] = appCheckToken;
    }

    return headers;
  }

  Future<http.Response> post(
    String path, {
    required Object body,
    Duration? timeout,
    bool requireAuth = true,
  }) async {
    final headers = await buildHeaders(requireAuth: requireAuth);
    final request = _http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (timeout != null) {
      return request.timeout(timeout);
    }
    return request;
  }

  Future<http.StreamedResponse> send(
    http.Request request, {
    Duration? timeout,
    bool requireAuth = true,
  }) async {
    final headers = await buildHeaders(requireAuth: requireAuth);
    request.headers.addAll(headers);
    final streamed = _http.send(request);
    if (timeout != null) {
      return streamed.timeout(timeout);
    }
    return streamed;
  }
}

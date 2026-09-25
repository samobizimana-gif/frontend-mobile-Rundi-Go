import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic body;

  ApiException({this.statusCode, required this.message, this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  ApiClient._private();
  static final ApiClient instance = ApiClient._private();

  Future<bool>? _refreshing;

  // ==========================================
  // 🌐 MÉTHODES PUBLIQUES
  // ==========================================
  Future<dynamic> get({
    required String baseUrl,
    required String path,
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _request('GET', baseUrl, path, query: query, auth: auth);

  Future<dynamic> post({
    required String baseUrl,
    required String path,
    Map<String, dynamic>? body,
    bool auth = true,
  }) => _request('POST', baseUrl, path, body: body, auth: auth);

  Future<dynamic> patch({
    required String baseUrl,
    required String path,
    Map<String, dynamic>? body,
    bool auth = true,
  }) => _request('PATCH', baseUrl, path, body: body, auth: auth);

  Future<dynamic> put({
    required String baseUrl,
    required String path,
    Map<String, dynamic>? body,
    bool auth = true,
  }) => _request('PUT', baseUrl, path, body: body, auth: auth);

  Future<dynamic> delete({
    required String baseUrl,
    required String path,
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _request('DELETE', baseUrl, path, query: query, auth: auth);

  // ==========================================
  // 📤 UPLOAD MULTIPART
  // ==========================================
  Future<dynamic> uploadFile({
    required String baseUrl,
    required String path,
    required File file,
    required String fileField,
    Map<String, String>? fields,
    bool auth = true,
    String method = 'POST',
  }) async {
    final url = _buildUrl(baseUrl, path, null);
    final request = http.MultipartRequest(method, url);

    if (auth) {
      final token = await StorageService.instance.getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    request.headers['Accept'] = 'application/json';

    if (fields != null) request.fields.addAll(fields);

    // 👉 Content-type selon le champ + extension
    final ext = file.path.split('.').last.toLowerCase();
    MediaType? contentType;

    if (fileField == 'image' || fileField == 'photo' || fileField == 'img') {
      // 👉 On force le JPEG pour maximiser la compatibilité OCR
      if (ext == 'png') {
        contentType = MediaType('image', 'png');
      } else if (ext == 'webp') {
        contentType = MediaType('image', 'webp');
      } else {
        contentType = MediaType('image', 'jpeg');
      }
    } else if (fileField == 'audio') {
      if (ext == 'wav') {
        contentType = MediaType('audio', 'wav');
      } else if (ext == 'mp3') {
        contentType = MediaType('audio', 'mpeg');
      } else if (ext == 'ogg') {
        contentType = MediaType('audio', 'ogg');
      } else {
        contentType = MediaType('audio', 'webm');
      }
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        fileField,
        file.path,
        contentType: contentType,
      ),
    );

    try {
      final streamed = await request.send().timeout(AppConfig.uploadTimeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401 && auth) {
        final ok = await _tryRefresh();
        if (ok) {
          return uploadFile(
            baseUrl: baseUrl,
            path: path,
            file: file,
            fileField: fileField,
            fields: fields,
            auth: auth,
            method: method,
          );
        }
        await StorageService.instance.clearTokens();
        throw ApiException(
          statusCode: 401,
          message: 'Session expirée. Reconnectez-vous.',
        );
      }

      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException("Délai d'envoi dépassé. Réessayez.");
    } on SocketException {
      throw NetworkException("Impossible de contacter le serveur.");
    }
  }

  // ==========================================
  // 🔧 MÉTHODE INTERNE PRINCIPALE
  // ==========================================
  Future<dynamic> _request(
    String method,
    String baseUrl,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    bool auth = true,
    bool isRetry = false,
  }) async {
    final url = _buildUrl(baseUrl, path, query);

    // 👇👇👇 LES HEADERS CRITIQUES 👇👇👇
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8', // ✅ OBLIGATOIRE
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await StorageService.instance.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    try {
      http.Response response;

      switch (method) {
        case 'GET':
          response = await http
              .get(url, headers: headers)
              .timeout(AppConfig.requestTimeout);
          break;
        case 'POST':
          // 👇👇👇 jsonEncode OBLIGATOIRE 👇👇👇
          response = await http
              .post(
                url,
                headers: headers,
                body: jsonEncode(body ?? {}), // ✅ jsonEncode
              )
              .timeout(AppConfig.requestTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(url, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(AppConfig.requestTimeout);
          break;
        case 'PUT':
          response = await http
              .put(url, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(AppConfig.requestTimeout);
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: headers)
              .timeout(AppConfig.requestTimeout);
          break;
        default:
          throw ApiException(message: 'Méthode HTTP inconnue : $method');
      }

      // 👉 Refresh auto si 401
      if (response.statusCode == 401 && auth && !isRetry) {
        final ok = await _tryRefresh();
        if (ok) {
          return _request(
            method,
            baseUrl,
            path,
            query: query,
            body: body,
            auth: auth,
            isRetry: true,
          );
        } else {
          await StorageService.instance.clearTokens();
          throw ApiException(
            statusCode: 401,
            message: 'Session expirée. Reconnectez-vous.',
          );
        }
      }

      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException("Le serveur met trop de temps à répondre.");
    } on SocketException {
      throw NetworkException("Impossible de contacter le serveur.");
    }
  }

  // ==========================================
  // 🔄 REFRESH TOKEN
  // ==========================================
  Future<bool> _tryRefresh() async {
    if (_refreshing != null) return _refreshing!;
    _refreshing = _doRefresh();
    final result = await _refreshing!;
    _refreshing = null;
    return result;
  }

  Future<bool> _doRefresh() async {
    try {
      final refresh = await StorageService.instance.getRefreshToken();
      if (refresh == null) return false;

      final response = await http
          .post(
            Uri.parse('${AppConfig.geoBaseUrl}/auth/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refresh}),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await StorageService.instance.saveTokens(
          access: data['access'],
          refresh: data['refresh'],
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // 🛠️ HELPERS
  // ==========================================
  Uri _buildUrl(String baseUrl, String path, Map<String, dynamic>? query) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  dynamic _handleResponse(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'Erreur inconnue';

    if (body is Map) {
      if (body['detail'] != null) {
        message = body['detail'].toString();
      } else {
        final firstKey = body.keys.first;
        final firstVal = body[firstKey];
        if (firstVal is List && firstVal.isNotEmpty) {
          message = '$firstKey : ${firstVal.first}';
        } else {
          message = '$firstKey : $firstVal';
        }
      }
    } else if (body is List && body.isNotEmpty) {
      message = body.first.toString();
    } else if (response.body.isNotEmpty) {
      message = response.body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      body: body,
    );
  }
}

import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html' as io;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = 'http://localhost:5000';

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath');
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final resolvedBody = body is String || body == null ? body : json.encode(body);
    final response = await _client.post(
      _uri(path),
      headers: {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      body: resolvedBody,
    );

    final data = _decode(response.body);
    _throwOnError(response.statusCode, data);
    if (data is Map<String, dynamic>) return data;
    if (data == null) return <String, dynamic>{};
    throw const ApiException(statusCode: 500, message: 'Unexpected response format');
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final resolvedBody = body is String || body == null ? body : json.encode(body);
    final response = await _client.put(
      _uri(path),
      headers: {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      body: resolvedBody,
    );

    final data = _decode(response.body);
    _throwOnError(response.statusCode, data);
    if (data is Map<String, dynamic>) return data;
    if (data == null) return <String, dynamic>{};
    throw const ApiException(statusCode: 500, message: 'Unexpected response format');
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final response = await _client.delete(
      _uri(path),
      headers: {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
    );
    final data = _decode(response.body);
    _throwOnError(response.statusCode, data);
    if (data is Map<String, dynamic>) return data;
    if (data == null) return <String, dynamic>{};
    throw const ApiException(statusCode: 500, message: 'Unexpected response format');
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final response = await _client.get(
      _uri(path),
      headers: headers,
    );

    final data = _decode(response.body);
    _throwOnError(response.statusCode, data);
    if (data is Map<String, dynamic>) return data;
    if (data == null) return <String, dynamic>{};
    throw const ApiException(statusCode: 500, message: 'Unexpected response format');
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    Map<String, XFile>? files,
    String? fileField,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    
    if (headers != null) {
      request.headers.addAll(headers);
    }
    
    if (fields != null) {
      request.fields.addAll(fields);
    }
    
    if (files != null) {
      for (final entry in files.entries) {
        final xFile = entry.value;
        final field = entry.key;
        final fileName = xFile.name;
        final fileExtension = fileName.split('.').last.toLowerCase();
        final contentType = MediaType('image', fileExtension == 'jpg' || fileExtension == 'jpeg' ? 'jpeg' : 'png');
        
        if (kIsWeb) {
          // For web, read bytes from XFile
          final bytes = await xFile.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              field,
              bytes,
              filename: fileName,
              contentType: contentType,
            ),
          );
        } else {
          // For mobile, use file path
          request.files.add(
            await http.MultipartFile.fromPath(
              field,
              xFile.path,
              filename: fileName,
              contentType: contentType,
            ),
          );
        }
      }
    }
    
    if (fileField != null && files != null && files.isNotEmpty) {
      final xFile = files.values.first;
      final fileName = xFile.name;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final contentType = MediaType('image', fileExtension == 'jpg' || fileExtension == 'jpeg' ? 'jpeg' : 'png');
      
      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            bytes,
            filename: fileName,
            contentType: contentType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            xFile.path,
            filename: fileName,
            contentType: contentType,
          ),
        );
      }
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    final data = _decode(response.body);
    _throwOnError(response.statusCode, data);
    if (data is Map<String, dynamic>) return data;
    if (data == null) return <String, dynamic>{};
    throw const ApiException(statusCode: 500, message: 'Unexpected response format');
  }

  dynamic _decode(String body) {
    if (body.isEmpty) return null;
    return json.decode(body);
  }

  void _throwOnError(int statusCode, dynamic data) {
    if (statusCode >= 200 && statusCode < 300) return;
    final message = data is Map<String, dynamic> ? data['message'] ?? data['error'] : 'Request failed';
    throw ApiException(statusCode: statusCode, message: message?.toString());
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    String? message,
  }) : message = message ?? 'Request failed with status $statusCode';

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}


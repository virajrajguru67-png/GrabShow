import 'dart:convert';

import '../../services/api_client.dart';

class AdminMovieService {
  AdminMovieService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> listMovies({int page = 1}) async {
    return _client.get('/admin/movies?page=$page');
  }

  Future<Map<String, dynamic>> createMovie(Map<String, dynamic> data) async {
    return _client.post(
      '/admin/movies',
      body: jsonEncode(data),
    );
  }

  Future<Map<String, dynamic>> updateMovie(String movieId, Map<String, dynamic> data) async {
    return _client.post(
      '/admin/movies/$movieId',
      headers: {'X-HTTP-Method-Override': 'PUT'},
      body: jsonEncode(data),
    );
  }

  Future<void> deleteMovie(String movieId) async {
    await _client.post(
      '/admin/movies/$movieId',
      headers: {'X-HTTP-Method-Override': 'DELETE'},
    );
  }
}


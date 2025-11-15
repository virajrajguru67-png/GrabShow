import '../models/admin_models.dart';
import '../services/api_client.dart';

class AdminRepository {
  AdminRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
      };

  Future<List<AdminMovie>> fetchMovies(String token) async {
    final response = await _apiClient.get(
      '/admin/movies',
      headers: _headers(token),
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((movie) => AdminMovie.fromJson(movie as Map<String, dynamic>))
        .toList();
  }

  Future<AdminMovie> createMovie(
      String token, Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      '/admin/movies',
      headers: _headers(token),
      body: payload,
    );
    return AdminMovie.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AdminMovie> updateMovie(
      String token, String movieId, Map<String, dynamic> payload) async {
    final response = await _apiClient.put(
      '/admin/movies/$movieId',
      headers: _headers(token),
      body: payload,
    );
    return AdminMovie.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMovie(String token, String movieId) async {
    await _apiClient.delete(
      '/admin/movies/$movieId',
      headers: _headers(token),
    );
  }

  Future<List<AdminShowtime>> fetchShowtimes(String token) async {
    final response = await _apiClient.get(
      '/admin/operations/showtimes',
      headers: _headers(token),
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => AdminShowtime.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminShowtime> createShowtime(
      String token, Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      '/admin/operations/showtimes',
      headers: _headers(token),
      body: payload,
    );
    return AdminShowtime.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AdminShowtime> updateShowtime(
    String token,
    String showtimeId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.put(
      '/admin/operations/showtimes/$showtimeId',
      headers: _headers(token),
      body: payload,
    );
    return AdminShowtime.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteShowtime(String token, String showtimeId) async {
    await _apiClient.delete(
      '/admin/operations/showtimes/$showtimeId',
      headers: _headers(token),
    );
  }

  Future<List<AdminAuditorium>> fetchAuditoriums(String token) async {
    final response = await _apiClient.get(
      '/admin/operations/auditoriums',
      headers: _headers(token),
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => AdminAuditorium.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminAuditorium> createAuditorium(
    String token, {
    required String cinemaId,
    required String cinemaName,
    required String name,
    required int capacity,
  }) async {
    final response = await _apiClient.post(
      '/admin/operations/auditoriums',
      headers: _headers(token),
      body: {
        'cinemaId': cinemaId,
        'cinemaName': cinemaName,
        'name': name,
        'capacity': capacity,
      },
    );
    return AdminAuditorium.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AdminAuditorium> updateAuditorium(
    String token,
    String auditoriumId, {
    String? cinemaId,
    String? cinemaName,
    String? name,
    int? capacity,
  }) async {
    final response = await _apiClient.put(
      '/admin/operations/auditoriums/$auditoriumId',
      headers: _headers(token),
      body: {
        if (cinemaId != null) 'cinemaId': cinemaId,
        if (cinemaName != null) 'cinemaName': cinemaName,
        if (name != null) 'name': name,
        if (capacity != null) 'capacity': capacity,
      },
    );
    return AdminAuditorium.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AdminAuditorium> updateSeatLayout(
    String token,
    String auditoriumId,
    SeatLayout layout,
  ) async {
    final response = await _apiClient.put(
      '/admin/operations/auditoriums/$auditoriumId/layout',
      headers: _headers(token),
      body: {
        'version': layout.version,
        'rows': layout.rows.map((row) => row.toJson()).toList(),
      },
    );
    return AdminAuditorium.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<AdminBooking>> fetchBookings(String token) async {
    final response = await _apiClient.get(
      '/admin/operations/bookings',
      headers: _headers(token),
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => AdminBooking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminBooking> cancelBooking(String token, String bookingId) async {
    final response = await _apiClient.post(
      '/admin/operations/bookings/$bookingId/cancel',
      headers: _headers(token),
    );
    return AdminBooking.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AdminBooking> refundBooking(String token, String bookingId) async {
    final response = await _apiClient.post(
      '/admin/operations/bookings/$bookingId/refund',
      headers: _headers(token),
    );
    return AdminBooking.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<SettlementTransaction>> fetchSettlements(String token) async {
    final response = await _apiClient.get(
      '/admin/operations/settlements/ledger',
      headers: _headers(token),
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) =>
            SettlementTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminUser>> fetchAdminUsers(String token) async {
    final response = await _apiClient.get(
      '/admin/operations/users',
      headers: _headers(token),
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => AdminUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminUser> inviteAdminUser(
    String token, {
    required String email,
    required String name,
    required List<AdminRole> roles,
  }) async {
    final response = await _apiClient.post(
      '/admin/operations/users/invite',
      headers: _headers(token),
      body: {
        'email': email,
        'name': name,
        'roles': roles.map((role) => role.name).toList(),
      },
    );
    return AdminUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AdminUser> updateAdminUser(
    String token,
    String userId, {
    List<AdminRole>? roles,
    String? status,
    String? name,
  }) async {
    final response = await _apiClient.put(
      '/admin/operations/users/$userId',
      headers: _headers(token),
      body: {
        if (roles != null) 'roles': roles.map((role) => role.name).toList(),
        if (status != null) 'status': status,
        if (name != null) 'name': name,
      },
    );
    return AdminUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<CampaignSegment>> fetchSegments(String token) async {
    final response = await _apiClient.get(
      '/admin/operations/notifications/segments',
      headers: _headers(token),
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => CampaignSegment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<NotificationCampaign>> fetchCampaigns(String token) async {
    final response = await _apiClient.get(
      '/admin/operations/notifications/campaigns',
      headers: _headers(token),
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) =>
            NotificationCampaign.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationCampaign> createCampaign(
    String token, {
    required String name,
    required String subject,
    required List<CampaignChannel> channels,
    required String segmentId,
    DateTime? scheduledAt,
  }) async {
    final response = await _apiClient.post(
      '/admin/operations/notifications/campaigns',
      headers: _headers(token),
      body: {
        'name': name,
        'subject': subject,
        'channel': channels.map((channel) => channel.name).toList(),
        'segmentId': segmentId,
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
      },
    );
    return NotificationCampaign.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  Future<PlatformSettings> fetchSettings(String token) async {
    final response = await _apiClient.get(
      '/admin/operations/settings',
      headers: _headers(token),
    );
    return PlatformSettings.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<PlatformSettings> updateSettings(
      String token, PlatformSettings settings) async {
    final response = await _apiClient.put(
      '/admin/operations/settings',
      headers: _headers(token),
      body: settings.toPayload(),
    );
    return PlatformSettings.fromJson(response['data'] as Map<String, dynamic>);
  }
}

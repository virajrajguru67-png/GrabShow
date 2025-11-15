import 'package:collection/collection.dart';

enum MovieStatus { draft, published }

MovieStatus movieStatusFromJson(String value) =>
    MovieStatus.values.firstWhere((status) => status.name == value,
        orElse: () => MovieStatus.draft);

enum SeatType { standard, premium, vip, accessible, couple }

SeatType seatTypeFromJson(String value) => SeatType.values
    .firstWhere((type) => type.name == value, orElse: () => SeatType.standard);

class SeatDefinition {
  const SeatDefinition({
    required this.seatId,
    required this.label,
    required this.type,
    this.isAisle = false,
    this.blocked = false,
  });

  final String seatId;
  final String label;
  final SeatType type;
  final bool isAisle;
  final bool blocked;

  SeatDefinition copyWith({
    String? seatId,
    String? label,
    SeatType? type,
    bool? isAisle,
    bool? blocked,
  }) {
    return SeatDefinition(
      seatId: seatId ?? this.seatId,
      label: label ?? this.label,
      type: type ?? this.type,
      isAisle: isAisle ?? this.isAisle,
      blocked: blocked ?? this.blocked,
    );
  }

  factory SeatDefinition.fromJson(Map<String, dynamic> json) {
    return SeatDefinition(
      seatId: json['seatId'] as String,
      label: json['label'] as String? ?? json['seatId'] as String,
      type: seatTypeFromJson((json['type'] as String?) ?? 'standard'),
      isAisle: json['isAisle'] as bool? ?? false,
      blocked: json['blocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'seatId': seatId,
        'label': label,
        'type': type.name,
        'isAisle': isAisle,
        'blocked': blocked,
      };
}

class SeatRow {
  const SeatRow({
    required this.rowLabel,
    required this.seats,
  });

  final String rowLabel;
  final List<SeatDefinition> seats;

  SeatRow copyWith({
    String? rowLabel,
    List<SeatDefinition>? seats,
  }) {
    return SeatRow(
      rowLabel: rowLabel ?? this.rowLabel,
      seats: seats ?? this.seats,
    );
  }

  factory SeatRow.fromJson(Map<String, dynamic> json) {
    return SeatRow(
      rowLabel: json['rowLabel'] as String,
      seats: (json['seats'] as List<dynamic>? ?? [])
          .map((seat) => SeatDefinition.fromJson(seat as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rowLabel': rowLabel,
        'seats': seats.map((seat) => seat.toJson()).toList(),
      };
}

class SeatLayout {
  const SeatLayout({
    required this.version,
    required this.updatedAt,
    required this.rows,
  });

  final int version;
  final DateTime updatedAt;
  final List<SeatRow> rows;

  SeatLayout copyWith({
    int? version,
    DateTime? updatedAt,
    List<SeatRow>? rows,
  }) {
    return SeatLayout(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      rows: rows ?? this.rows,
    );
  }

  factory SeatLayout.fromJson(Map<String, dynamic> json) {
    return SeatLayout(
      version: json['version'] as int? ?? 1,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      rows: (json['rows'] as List<dynamic>? ?? [])
          .map((row) => SeatRow.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'rows': rows.map((row) => row.toJson()).toList(),
      };
}

class SeatInventoryStats {
  const SeatInventoryStats({
    required this.totalSeats,
    required this.availableSeats,
    required this.blockedSeats,
  });

  final int totalSeats;
  final int availableSeats;
  final int blockedSeats;

  factory SeatInventoryStats.fromJson(Map<String, dynamic> json) {
    return SeatInventoryStats(
      totalSeats: (json['totalSeats'] as num?)?.toInt() ?? 0,
      availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 0,
      blockedSeats: (json['blockedSeats'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAuditorium {
  const AdminAuditorium({
    required this.id,
    required this.cinemaId,
    required this.cinemaName,
    required this.name,
    required this.capacity,
    required this.layout,
    this.stats,
  });

  final String id;
  final String cinemaId;
  final String cinemaName;
  final String name;
  final int capacity;
  final SeatLayout layout;
  final SeatInventoryStats? stats;

  factory AdminAuditorium.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>?;
    return AdminAuditorium(
      id: json['id'] as String,
      cinemaId: json['cinemaId'] as String,
      cinemaName: json['cinemaName'] as String,
      name: json['name'] as String,
      capacity: json['capacity'] as int? ?? 0,
      layout: SeatLayout.fromJson(json['layout'] as Map<String, dynamic>),
      stats: statsJson != null ? SeatInventoryStats.fromJson(statsJson) : null,
    );
  }

  AdminAuditorium copyWith({
    String? cinemaId,
    String? cinemaName,
    String? name,
    int? capacity,
    SeatLayout? layout,
    SeatInventoryStats? stats,
  }) {
    return AdminAuditorium(
      id: id,
      cinemaId: cinemaId ?? this.cinemaId,
      cinemaName: cinemaName ?? this.cinemaName,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      layout: layout ?? this.layout,
      stats: stats ?? this.stats,
    );
  }
}

class PricingTier {
  const PricingTier({
    required this.id,
    required this.label,
    required this.price,
    required this.seatTypes,
  });

  final String id;
  final String label;
  final double price;
  final List<SeatType> seatTypes;

  factory PricingTier.fromJson(Map<String, dynamic> json) {
    return PricingTier(
      id: json['id'] as String? ?? '',
      label: json['label'] as String,
      price: (json['price'] as num).toDouble(),
      seatTypes: (json['seatTypes'] as List<dynamic>? ?? [])
          .map((value) => seatTypeFromJson(value as String))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'label': label,
        'price': price,
        'seatTypes': seatTypes.map((type) => type.name).toList(),
      };
}

enum ShowtimeStatus { scheduled, onSale, completed, cancelled }

ShowtimeStatus showtimeStatusFromJson(String value) {
  switch (value) {
    case 'on-sale':
      return ShowtimeStatus.onSale;
    default:
      return ShowtimeStatus.values.firstWhere(
        (status) => status.name == value.replaceAll('-', ''),
        orElse: () => ShowtimeStatus.scheduled,
      );
  }
}

String showtimeStatusToJson(ShowtimeStatus status) {
  switch (status) {
    case ShowtimeStatus.onSale:
      return 'on-sale';
    default:
      return status.name;
  }
}

class AdminShowtime {
  const AdminShowtime({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.cinemaId,
    required this.cinemaName,
    required this.auditoriumId,
    required this.auditoriumName,
    required this.startsAt,
    required this.endsAt,
    required this.basePrice,
    required this.pricingTiers,
    required this.status,
    required this.seatLayoutVersion,
  });

  final String id;
  final String movieId;
  final String movieTitle;
  final String cinemaId;
  final String cinemaName;
  final String auditoriumId;
  final String auditoriumName;
  final DateTime startsAt;
  final DateTime endsAt;
  final double basePrice;
  final List<PricingTier> pricingTiers;
  final ShowtimeStatus status;
  final int seatLayoutVersion;

  factory AdminShowtime.fromJson(Map<String, dynamic> json) {
    return AdminShowtime(
      id: json['id'] as String,
      movieId: json['movieId'] as String,
      movieTitle: json['movieTitle'] as String,
      cinemaId: json['cinemaId'] as String,
      cinemaName: json['cinemaName'] as String,
      auditoriumId: json['auditoriumId'] as String,
      auditoriumName: json['auditoriumName'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      basePrice: (json['basePrice'] as num).toDouble(),
      pricingTiers: (json['pricingTiers'] as List<dynamic>? ?? [])
          .map((tier) => PricingTier.fromJson(tier as Map<String, dynamic>))
          .toList(),
      status: showtimeStatusFromJson(json['status'] as String),
      seatLayoutVersion: json['seatLayoutVersion'] as int? ?? 1,
    );
  }
}

class AdminMovie {
  const AdminMovie({
    required this.id,
    required this.title,
    required this.slug,
    required this.genres,
    required this.languages,
    required this.status,
    this.durationMinutes,
  });

  final String id;
  final String title;
  final String slug;
  final List<String> genres;
  final List<String> languages;
  final MovieStatus status;
  final int? durationMinutes;

  factory AdminMovie.fromJson(Map<String, dynamic> json) {
    return AdminMovie(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((genre) => genre.toString())
          .toList(),
      languages: (json['languages'] as List<dynamic>? ?? [])
          .map((language) => language.toString())
          .toList(),
      status: movieStatusFromJson(json['status'] as String? ?? 'draft'),
      durationMinutes: json['durationMinutes'] as int?,
    );
  }
}

enum BookingStatus { reserved, confirmed, cancelled, refunded }

BookingStatus bookingStatusFromJson(String value) =>
    BookingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => BookingStatus.reserved,
    );

class BookingTicket {
  const BookingTicket({
    required this.seatId,
    required this.seatLabel,
    required this.price,
    required this.tierId,
  });

  final String seatId;
  final String seatLabel;
  final double price;
  final String tierId;

  factory BookingTicket.fromJson(Map<String, dynamic> json) {
    return BookingTicket(
      seatId: json['seatId'] as String,
      seatLabel: json['seatLabel'] as String,
      price: (json['price'] as num).toDouble(),
      tierId: json['tierId'] as String,
    );
  }
}

class BookingAuditEntry {
  const BookingAuditEntry({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.actor,
  });

  final String id;
  final String type;
  final String message;
  final DateTime createdAt;
  final String actor;

  factory BookingAuditEntry.fromJson(Map<String, dynamic> json) {
    return BookingAuditEntry(
      id: json['id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      actor: json['actor'] as String,
    );
  }
}

class AdminBooking {
  const AdminBooking({
    required this.id,
    required this.reference,
    required this.movieTitle,
    required this.showtimeId,
    required this.purchaserEmail,
    required this.purchaserName,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.purchasedAt,
    required this.tickets,
    required this.auditLog,
  });

  final String id;
  final String reference;
  final String movieTitle;
  final String showtimeId;
  final String purchaserEmail;
  final String purchaserName;
  final BookingStatus status;
  final double totalAmount;
  final String currency;
  final DateTime purchasedAt;
  final List<BookingTicket> tickets;
  final List<BookingAuditEntry> auditLog;

  factory AdminBooking.fromJson(Map<String, dynamic> json) {
    return AdminBooking(
      id: json['id'] as String,
      reference: json['reference'] as String,
      movieTitle: json['movieTitle'] as String,
      showtimeId: json['showtimeId'] as String,
      purchaserEmail: json['purchaserEmail'] as String,
      purchaserName: json['purchaserName'] as String,
      status: bookingStatusFromJson(json['status'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency'] as String,
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      tickets: (json['tickets'] as List<dynamic>? ?? [])
          .map((ticket) =>
              BookingTicket.fromJson(ticket as Map<String, dynamic>))
          .toList(),
      auditLog: (json['auditLog'] as List<dynamic>? ?? [])
          .map((entry) =>
              BookingAuditEntry.fromJson(entry as Map<String, dynamic>))
          .sorted((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }
}

enum SettlementStatus { pending, processing, completed }

SettlementStatus settlementStatusFromJson(String value) =>
    SettlementStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SettlementStatus.pending,
    );

class SettlementTransaction {
  const SettlementTransaction({
    required this.id,
    required this.gateway,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.fees,
    required this.netPayout,
    this.settledAt,
    required this.bookingReference,
  });

  final String id;
  final String gateway;
  final String transactionId;
  final double amount;
  final String currency;
  final SettlementStatus status;
  final double fees;
  final double netPayout;
  final DateTime? settledAt;
  final String bookingReference;

  factory SettlementTransaction.fromJson(Map<String, dynamic> json) {
    return SettlementTransaction(
      id: json['id'] as String,
      gateway: json['gateway'] as String,
      transactionId: json['transactionId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      status: settlementStatusFromJson(json['status'] as String),
      fees: (json['fees'] as num).toDouble(),
      netPayout: (json['netPayout'] as num).toDouble(),
      settledAt: (json['settledAt'] as String?) != null
          ? DateTime.tryParse(json['settledAt'] as String)
          : null,
      bookingReference: json['bookingReference'] as String,
    );
  }
}

enum AdminRole { owner, finance, content, operations, support, marketing }

AdminRole adminRoleFromJson(String value) => AdminRole.values
    .firstWhere((role) => role.name == value, orElse: () => AdminRole.support);

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.roles,
    required this.lastActiveAt,
    required this.status,
  });

  final String id;
  final String email;
  final String name;
  final List<AdminRole> roles;
  final DateTime lastActiveAt;
  final String status;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((role) => adminRoleFromJson(role as String))
          .toList(),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'invited',
    );
  }
}

enum CampaignChannel { email, sms, push }

CampaignChannel campaignChannelFromJson(String value) =>
    CampaignChannel.values.firstWhere((channel) => channel.name == value,
        orElse: () => CampaignChannel.email);

enum CampaignStatus { draft, scheduled, inFlight, completed }

CampaignStatus campaignStatusFromJson(String value) {
  switch (value) {
    case 'in-flight':
      return CampaignStatus.inFlight;
    default:
      return CampaignStatus.values.firstWhere(
        (status) => status.name == value.replaceAll('-', ''),
        orElse: () => CampaignStatus.draft,
      );
  }
}

class CampaignSegment {
  const CampaignSegment({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory CampaignSegment.fromJson(Map<String, dynamic> json) {
    return CampaignSegment(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}

class NotificationCampaign {
  const NotificationCampaign({
    required this.id,
    required this.name,
    required this.subject,
    required this.channels,
    required this.status,
    this.scheduledAt,
    required this.createdAt,
    required this.segmentId,
    required this.sent,
    required this.opened,
    required this.clicked,
  });

  final String id;
  final String name;
  final String subject;
  final List<CampaignChannel> channels;
  final CampaignStatus status;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final String segmentId;
  final int sent;
  final int opened;
  final int clicked;

  factory NotificationCampaign.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    return NotificationCampaign(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      channels: (json['channel'] as List<dynamic>? ??
              json['channels'] as List<dynamic>? ??
              [])
          .map((channel) => campaignChannelFromJson(channel as String))
          .toList(),
      status: campaignStatusFromJson(json['status'] as String? ?? 'draft'),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      segmentId: json['segmentId'] as String,
      sent: (stats['sent'] as num?)?.toInt() ?? 0,
      opened: (stats['opened'] as num?)?.toInt() ?? 0,
      clicked: (stats['clicked'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlatformSettings {
  const PlatformSettings({
    required this.razorpayKey,
    required this.stripeKey,
    required this.settlementDays,
    required this.cgst,
    required this.sgst,
    required this.convenienceFee,
    required this.theatreName,
    required this.supportEmail,
    required this.contactNumber,
    required this.address,
    required this.termsUrl,
    required this.privacyUrl,
    required this.refundWindowHours,
    required this.updatedAt,
  });

  final String razorpayKey;
  final String stripeKey;
  final int settlementDays;
  final double cgst;
  final double sgst;
  final double convenienceFee;
  final String theatreName;
  final String supportEmail;
  final String contactNumber;
  final String address;
  final String termsUrl;
  final String privacyUrl;
  final int refundWindowHours;
  final DateTime updatedAt;

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>? ?? {};
    final taxes = json['taxes'] as Map<String, dynamic>? ?? {};
    final theatre = json['theatre'] as Map<String, dynamic>? ?? {};
    final policies = json['policies'] as Map<String, dynamic>? ?? {};
    return PlatformSettings(
      razorpayKey: payment['razorpayKey'] as String? ?? '',
      stripeKey: payment['stripeKey'] as String? ?? '',
      settlementDays: (payment['settlementDays'] as num?)?.toInt() ?? 2,
      cgst: (taxes['cgst'] as num?)?.toDouble() ?? 0,
      sgst: (taxes['sgst'] as num?)?.toDouble() ?? 0,
      convenienceFee: (taxes['convenienceFee'] as num?)?.toDouble() ?? 0,
      theatreName: theatre['name'] as String? ?? '',
      supportEmail: theatre['supportEmail'] as String? ?? '',
      contactNumber: theatre['contactNumber'] as String? ?? '',
      address: theatre['address'] as String? ?? '',
      termsUrl: policies['termsUrl'] as String? ?? '',
      privacyUrl: policies['privacyUrl'] as String? ?? '',
      refundWindowHours: (policies['refundWindowHours'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toPayload() => {
        'payment': {
          'razorpayKey': razorpayKey,
          'stripeKey': stripeKey,
          'settlementDays': settlementDays,
        },
        'taxes': {
          'cgst': cgst,
          'sgst': sgst,
          'convenienceFee': convenienceFee,
        },
        'theatre': {
          'name': theatreName,
          'supportEmail': supportEmail,
          'contactNumber': contactNumber,
          'address': address,
        },
        'policies': {
          'termsUrl': termsUrl,
          'privacyUrl': privacyUrl,
          'refundWindowHours': refundWindowHours,
        },
      };
}

class Report {
  final String id;
  final String reporterId;
  final String description;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        reporterId: json['reporter_id'] as String,
        description: json['description'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        photoUrl: json['photo_url'] as String?,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class Report {
  final String id;
  final String reporterId;
  final String reportType; // 'litter', 'infrastructure', 'lighting', 'development', 'power'
  final String description;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String status;
  final String? category;
  final String? priority;
  
  // Litter specific
  final String? wasteType;
  final String? scale;
  final String? proximityHazard;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reportType,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    required this.status,
    this.category,
    this.priority,
    this.wasteType,
    this.scale,
    this.proximityHazard,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        reporterId: json['reporter_id'] as String,
        reportType: json['report_type'] as String? ?? 'litter',
        description: json['description'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        photoUrl: json['photo_url'] as String?,
        status: json['status'] as String,
        category: json['category'] as String?,
        priority: json['priority'] as String?,
        wasteType: json['waste_type'] as String?,
        scale: json['scale'] as String?,
        proximityHazard: json['proximity_hazard'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

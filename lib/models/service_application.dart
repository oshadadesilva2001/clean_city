class ServiceApplication {
  final String id;
  final String userId;
  final String serviceType; // 'Birth Certificate', 'Passport', 'NIC', 'Driving License'
  final Map<String, dynamic> formData;
  final String status; // 'pending', 'processing', 'completed', 'rejected'
  final DateTime createdAt;

  ServiceApplication({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.formData,
    required this.status,
    required this.createdAt,
  });

  factory ServiceApplication.fromJson(Map<String, dynamic> json) {
    return ServiceApplication(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      serviceType: json['service_type'] as String,
      formData: json['form_data'] as Map<String, dynamic>,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'service_type': serviceType,
        'form_data': formData,
        'status': status,
      };
}

class Assignment {
  final String id;
  final String reportId;
  final String workerId;
  final String assignedBy;
  final String? note;
  final DateTime assignedAt;
  final DateTime? completedAt;

  const Assignment({
    required this.id,
    required this.reportId,
    required this.workerId,
    required this.assignedBy,
    this.note,
    required this.assignedAt,
    this.completedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'] as String,
        reportId: json['report_id'] as String,
        workerId: json['worker_id'] as String,
        assignedBy: json['assigned_by'] as String,
        note: json['note'] as String?,
        assignedAt: DateTime.parse(json['assigned_at'] as String),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );

  bool get isCompleted => completedAt != null;
}

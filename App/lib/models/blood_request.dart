class BloodRequest {
  final String id;
  final String hospitalName;
  final String city;
  final String hospitalAddress;
  final String bloodGroup;
  final String urgency; // CRITICAL, HIGH, MEDIUM, LOW
  final int unitsNeeded;
  final String status; // PENDING, ACCEPTED, FULFILLED, CANCELLED
  final String patientName;
  final String caseDescription;
  final String contactNumber;
  final double distance;
  final DateTime createdAt;
  final String? cancellationReason;

  BloodRequest({
    required this.id,
    required this.hospitalName,
    required this.city,
    required this.hospitalAddress,
    required this.bloodGroup,
    required this.urgency,
    required this.unitsNeeded,
    required this.status,
    required this.patientName,
    required this.caseDescription,
    required this.contactNumber,
    required this.distance,
    required this.createdAt,
    this.cancellationReason,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] ?? '',
      hospitalName: json['hospital_name'] ?? '',
      city: json['city'] ?? '',
      hospitalAddress: json['hospital_address'] ?? '',
      bloodGroup: json['blood_group'] ?? '',
      urgency: json['urgency'] ?? 'MEDIUM',
      unitsNeeded: json['units_needed'] ?? 1,
      status: json['status'] ?? 'PENDING',
      patientName: json['patient_name'] ?? '',
      caseDescription: json['case_description'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      cancellationReason: json['cancellation_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospital_name': hospitalName,
      'city': city,
      'hospital_address': hospitalAddress,
      'blood_group': bloodGroup,
      'urgency': urgency,
      'units_needed': unitsNeeded,
      'status': status,
      'patient_name': patientName,
      'case_description': caseDescription,
      'contact_number': contactNumber,
      'distance': distance,
      'created_at': createdAt.toIso8601String(),
      'cancellation_reason': cancellationReason,
    };
  }
}

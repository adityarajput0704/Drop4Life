class BloodRequest {
  final String id;
  final String hospitalName;
  final String city;
  final String hospitalAddress;
  final String bloodGroup;
  final String urgency;
  final int unitsNeeded;
  final String status;
  final String patientName;
  final String caseDescription;
  final String contactNumber;
  final double distance;
  final DateTime createdAt;
  final String? cancellationReason;
  final double? hospitalLat;
  final double? hospitalLng;

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
    this.hospitalLat,
    this.hospitalLng,
  });

  // Backend sends 'open' — Flutter UI expects 'PENDING'
  // Backend sends 'fulfilled' — Flutter UI expects 'FULFILLED'
  static String _normalizeStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'open':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'fulfilled':
        return 'FULFILLED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return 'PENDING';
    }
  }

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      // Backend sends int id — convert to String
      id: json['id']?.toString() ?? '',
      hospitalName: json['hospital_name'] ?? '',
      // Backend field is hospital_city, not city
      city: json['hospital_city'] ?? json['city'] ?? '',
      // Backend doesn't send address — graceful fallback
      hospitalAddress: json['hospital_address'] ?? '',
      bloodGroup: json['blood_group'] ?? '',
      // Backend sends lowercase — normalize to uppercase
      urgency: (json['urgency'] ?? 'medium').toString().toUpperCase(),
      unitsNeeded: json['units_needed'] ?? 1,
      status: _normalizeStatus(json['status']),
      patientName: json['patient_name'] ?? '',
      // Backend field is notes, not case_description
      caseDescription: json['notes'] ?? json['case_description'] ?? '',
      // Backend field is hospital_phone, not contact_number
      contactNumber: json['hospital_phone'] ?? json['contact_number'] ?? '',
      // Backend doesn't send distance — default to 0.0
      distance: (json['distance'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      cancellationReason: json['cancellation_reason'],
      hospitalLat: (json['hospital_lat'] as num?)?.toDouble(),
      hospitalLng: (json['hospital_lng'] as num?)?.toDouble(),
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

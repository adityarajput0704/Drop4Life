class BloodRequest {
  final String id;
  final String hospitalName;
  final String patientName;
  final String bloodGroup;
  final String urgency; // CRITICAL, HIGH, MEDIUM, LOW
  final String city;
  final String address;
  final int units;
  final String caseDescription;
  final String phone;

  BloodRequest({
    required this.id,
    required this.hospitalName,
    required this.patientName,
    required this.bloodGroup,
    required this.urgency,
    required this.city,
    required this.address,
    required this.units,
    required this.caseDescription,
    required this.phone,
  });
}

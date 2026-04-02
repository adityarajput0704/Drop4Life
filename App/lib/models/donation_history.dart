class DonationHistory {
  final String id;
  final String hospitalName;
  final String bloodGroup;
  final DateTime date;
  final String status; // FULFILLED, ACCEPTED, CANCELLED

  DonationHistory({
    required this.id,
    required this.hospitalName,
    required this.bloodGroup,
    required this.date,
    required this.status,
  });
}

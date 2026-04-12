class Donor {
  final String id;
  final String fullName;
  final String email;
  final String bloodGroup;
  final String city;
  final int age;
  final bool isAvailable;
  final int totalDonations;
  final int livesSaved;
  final DateTime? lastDonation;

  // Cooldown fields — new
  final bool isInCooldown;
  final String? cooldownUntil;
  final int daysRemaining;

  Donor({
    required this.id,
    required this.fullName,
    required this.email,
    required this.bloodGroup,
    required this.city,
    required this.age,
    required this.isAvailable,
    this.totalDonations = 0,
    this.livesSaved = 0,
    this.lastDonation,
    this.isInCooldown = false,
    this.cooldownUntil,
    this.daysRemaining = 0,
  });

  factory Donor.fromJson(Map<String, dynamic> json) {
    bool parseAvailability(dynamic value) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'available';
      return true;
    }

    return Donor(
      id:             json['id']?.toString() ?? '',
      fullName:       json['full_name'] ?? '',
      email:          json['email'] ?? '',
      bloodGroup:     json['blood_group'] ?? '',
      city:           json['city'] ?? '',
      age:            json['age'] ?? 0,
      isAvailable:    parseAvailability(json['availability'] ?? json['is_available']),
      totalDonations: json['total_donations'] ?? 0,
      livesSaved:     json['lives_saved'] ?? 0,
      lastDonation:   json['last_donation'] != null
          ? DateTime.tryParse(json['last_donation'])
          : null,
      // Cooldown
      isInCooldown:   json['is_in_cooldown'] ?? false,
      cooldownUntil:  json['cooldown_until'],
      daysRemaining:  json['days_remaining'] ?? 0,
    );
  }

  // copyWith updated to include new fields
  Donor copyWith({
    String? id, String? fullName, String? email,
    String? bloodGroup, String? city, int? age,
    bool? isAvailable, int? totalDonations,
    int? livesSaved, DateTime? lastDonation,
    bool? isInCooldown, String? cooldownUntil, int? daysRemaining,
  }) {
    return Donor(
      id:             id ?? this.id,
      fullName:       fullName ?? this.fullName,
      email:          email ?? this.email,
      bloodGroup:     bloodGroup ?? this.bloodGroup,
      city:           city ?? this.city,
      age:            age ?? this.age,
      isAvailable:    isAvailable ?? this.isAvailable,
      totalDonations: totalDonations ?? this.totalDonations,
      livesSaved:     livesSaved ?? this.livesSaved,
      lastDonation:   lastDonation ?? this.lastDonation,
      isInCooldown:   isInCooldown ?? this.isInCooldown,
      cooldownUntil:  cooldownUntil ?? this.cooldownUntil,
      daysRemaining:  daysRemaining ?? this.daysRemaining,
    );
  }
}
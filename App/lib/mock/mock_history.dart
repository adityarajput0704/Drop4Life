import '../models/donation_history.dart';

final List<DonationHistory> mockHistory = [
  DonationHistory(
    id: 'hist_1',
    hospitalName: 'City General Hospital',
    bloodGroup: 'O+',
    date: DateTime(2023, 10, 24),
    status: 'FULFILLED',
  ),
  DonationHistory(
    id: 'hist_2',
    hospitalName: 'St. Jude Medical Center',
    bloodGroup: 'O+',
    date: DateTime(2023, 8, 12),
    status: 'ACCEPTED',
  ),
  DonationHistory(
    id: 'hist_3',
    hospitalName: 'Red Cross Donation Drive',
    bloodGroup: 'O+',
    date: DateTime(2023, 5, 5),
    status: 'CANCELLED',
  ),
];

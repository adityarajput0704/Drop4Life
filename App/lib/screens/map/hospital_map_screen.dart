import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/blood_request.dart';
import '../../providers/donor_provider.dart';

class HospitalMapScreen extends StatelessWidget {
  final BloodRequest request;
  final double hospitalLat;
  final double hospitalLng;

  const HospitalMapScreen({
    super.key,
    required this.request,
    required this.hospitalLat,
    required this.hospitalLng,
  });

  Future<void> _openDirections() async {
    final googleMapsApp = Uri.parse(
      'google.navigation:q=$hospitalLat,$hospitalLng&mode=d',
    );
    final googleMapsBrowser = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$hospitalLat,$hospitalLng'
      '&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleMapsApp)) {
        await launchUrl(googleMapsApp);
      } else {
        await launchUrl(
          googleMapsBrowser,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      await launchUrl(
        googleMapsBrowser,
        mode: LaunchMode.platformDefault,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donor = context.read<DonorProvider>().donor;
    final donorLat = donor?.latitude ?? 0.0;
    final donorLng = donor?.longitude ?? 0.0;
    final hasDonorLoc = donorLat != 0.0 && donorLng != 0.0;

    final hospitalPoint = LatLng(hospitalLat, hospitalLng);
    final donorPoint    = LatLng(donorLat, donorLng);

    final centerLat = hasDonorLoc
        ? (donorLat + hospitalLat) / 2
        : hospitalLat;
    final centerLng = hasDonorLoc
        ? (donorLng + hospitalLng) / 2
        : hospitalLng;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          request.hospitalName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions),
            tooltip: 'Open in Maps',
            onPressed: _openDirections,   // ← single clean reference
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: hasDonorLoc ? 12.0 : 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.drop4life',
              ),

              if (hasDonorLoc)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [donorPoint, hospitalPoint],
                      strokeWidth: 4,
                      color: Colors.red.withOpacity(0.7),
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  // Hospital marker
                  Marker(
                    point: hospitalPoint,
                    width: 80,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            request.hospitalName.length > 12
                                ? '${request.hospitalName.substring(0, 12)}...'
                                : request.hospitalName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.local_hospital,
                            color: Colors.red, size: 28),
                      ],
                    ),
                  ),

                  // Donor marker
                  if (hasDonorLoc)
                    Marker(
                      point: donorPoint,
                      width: 60,
                      height: 60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.person_pin_circle,
                              color: Colors.blue, size: 28),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Bottom card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.hospitalName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.city,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _openDirections,  // ← single clean reference
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
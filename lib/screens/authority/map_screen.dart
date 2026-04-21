import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import 'report_detail_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  Color _markerColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident Map')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ReportService.streamAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = (snapshot.data ?? [])
              .map((e) => Report.fromJson(e))
              .toList();

          if (reports.isEmpty) {
            return const Center(child: Text('No incidents reported yet.'));
          }

          final center =
              LatLng(reports.first.latitude, reports.first.longitude);

          final markers = reports.map((r) {
            return Marker(
              point: LatLng(r.latitude, r.longitude),
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(report: r),
                  ),
                ),
                child: Icon(
                  Icons.location_pin,
                  size: 36,
                  color: _markerColor(r.status),
                ),
              ),
            );
          }).toList();

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.clean_city',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _LegendItem(color: Colors.red, label: 'Pending'),
                        SizedBox(height: 4),
                        _LegendItem(color: Colors.orange, label: 'Assigned'),
                        SizedBox(height: 4),
                        _LegendItem(color: Colors.green, label: 'Completed'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_pin, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

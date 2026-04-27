import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/groq_service.dart';
import '../../services/report_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/photo_picker_widget.dart';

enum ReportType { litter, infrastructure, lighting, development, power }

class SubmitReportScreen extends StatefulWidget {
  final ReportType initialType;
  const SubmitReportScreen({super.key, this.initialType = ReportType.litter});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  XFile? _image;
  Position? _position;
  bool _locating = false;
  bool _submitting = false;

  late ReportType _currentType;
  String? _subType;
  String? _scale;
  String? _hazard;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _getLocation();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _position = pos);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location error: $e')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Map<String, List<String>> get _options => {
    'litter': [
      'Domestic: Household bags, food waste',
      'Plastic/Recyclable: Bottles, packaging',
      'Construction: Bricks, cement, debris',
      'Electronic (E-waste): Batteries, old appliances',
      'Hazardous: Medical waste, chemicals, sharp objects',
    ],
    'infrastructure': [
      'Road Surface: Potholes, cracks, or slippery road',
      'Drainage: Overflowing gutters, blocked culverts',
      'Signage: Missing signs, broken traffic lights',
      'Pedestrian Safety: Broken sidewalks, overgrown bushes',
    ],
    'lighting': [
      'Functional: Flickering, off at night, on during day',
      'Hardware: Broken glass, leaning pole, exposed wiring',
      'Vegetation: Tree branches covering the lamp',
    ],
    'development': [
      'Unpaved Roads: Gravel road needs tarring/concreting',
      'New Lighting: Dark Zones where no poles exist',
      'Public Amenities: Lack of bus halts, toilets, bins',
      'Connectivity: Lack of fiber/broadband or mobile signal',
    ],
    'power': [
      'Total Blackout',
      'Phase Failure',
      'Voltage Fluctuation',
      'Scheduled Interruption (Not Notified)',
    ],
  };

  String get _title => switch (_currentType) {
    ReportType.litter => 'Report Litter',
    ReportType.infrastructure => 'Road & Infra Issue',
    ReportType.lighting => 'Street Light Issue',
    ReportType.development => 'Development Request',
    ReportType.power => 'Power Cut Report',
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detecting location... Please wait.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final userId = AuthService.currentUser!.id;
      String? photoPath;
      if (_image != null) photoPath = await StorageService.uploadPhoto(_image!, userId);
      
      final reportId = await ReportService.createReport(
        reporterId: userId,
        reportType: _currentType.name,
        description: _descCtrl.text.trim(),
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        photoUrl: photoPath,
        wasteType: _subType,
        scale: _scale,
        proximityHazard: _hazard,
      );

      GroqService.classifyReport(_descCtrl.text).then((f) => 
        ReportService.updateAiFields(reportId, f['category']!, f['priority']!)
      ).catchError((_) {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: PhotoPickerWidget(image: _image, onImageSelected: (f) => setState(() => _image = f)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLocationCard(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: InputDecoration(hintText: 'Describe the issue...', labelText: 'Description'),
                      maxLines: 3,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Type Details',
                      value: _subType,
                      items: _options[_currentType.name]!,
                      onChanged: (v) => setState(() => _subType = v),
                    ),
                    if (_currentType == ReportType.litter) ...[
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Scale',
                        value: _scale,
                        items: ['Small', 'Medium', 'Large (Illegal Dumping)'],
                        onChanged: (v) => setState(() => _scale = v),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Proximity',
                        value: _hazard,
                        items: ['Near Water Source', 'Near School/Park', 'Blocking Drain'],
                        onChanged: (v) => setState(() => _hazard = v),
                      ),
                    ],
                    const SizedBox(height: 40),
                    LoadingButton(label: 'Submit ${_title}', isLoading: _submitting, onPressed: _submit),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _position != null ? Colors.green : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(_position != null ? Icons.location_on : Icons.location_searching, color: _position != null ? Colors.green : Colors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(_position != null ? 'Location Detected' : 'Detecting Location...', style: TextStyle(fontWeight: FontWeight.bold))),
          if (_locating) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

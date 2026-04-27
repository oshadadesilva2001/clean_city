import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/service_application.dart';
import '../../services/auth_service.dart';
import '../../services/service_application_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/loading_button.dart';

class ServiceApplicationScreen extends StatefulWidget {
  final String serviceName;

  const ServiceApplicationScreen({super.key, required this.serviceName});

  @override
  State<ServiceApplicationScreen> createState() => _ServiceApplicationScreenState();
}

class _ServiceApplicationScreenState extends State<ServiceApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final Map<String, File> _selectedFiles = {};
  bool _submitting = false;

  List<Widget> _buildFormFields() {
    switch (widget.serviceName) {
      case 'Birth Certificate':
        return [
          _buildTextField('Full Name', 'full_name'),
          _buildTextField('Birth Certificate Number', 'cert_number'),
          _buildTextField('Registration District', 'district'),
          _buildTextField('Divisional Secretariat', 'ds_office'),
          _buildDateField('Date of Birth', 'dob'),
          _buildFilePickerField("Applicant's NIC or Passport (PDF/PNG)", 'id_doc'),
        ];
      case 'Passport':
        return [
          _buildFilePickerField('Original NIC (with photocopy)', 'nic_doc'),
          _buildFilePickerField('Original Birth Certificate (with photocopy)', 'bc_doc'),
          _buildFilePickerField('Studio Acknowledgement Note', 'studio_doc'),
          _buildFilePickerField('Marriage Certificate (if applicable)', 'marriage_doc', required: false),
          _buildFilePickerField('Professional Certificates (optional)', 'prof_doc', required: false),
        ];
      case 'NIC':
        return [
          _buildFilePickerField('Certified Application Form (GN signed)', 'gn_form_doc'),
          _buildFilePickerField('Original Birth Certificate', 'bc_doc'),
          _buildFilePickerField('Studio Acknowledgement Note', 'studio_doc'),
          _buildFilePickerField('Divisional Secretary Certification', 'ds_cert_doc'),
        ];
      case 'Driving License':
        return [
          _buildTextField('NIC or Passport Number', 'id_number'),
          _buildFilePickerField('Medical Fitness Certificate (NTMI)', 'medical_doc'),
          _buildFilePickerField('Original Birth Certificate', 'bc_doc'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Note: Digital Photo & Fingerprints will be captured on-site at the Department of Motor Traffic.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
            ),
          ),
        ];
      default:
        return [const Text('Service form not found.')];
    }
  }

  Widget _buildTextField(String label, String key, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
        onSaved: (v) => _formData[key] = v,
      ),
    );
  }

  Widget _buildDateField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              _formData[key] = date.toIso8601String().split('T')[0];
            });
          }
        },
        controller: TextEditingController(text: _formData[key] ?? ''),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildFilePickerField(String label, String key, {bool required = true}) {
    final file = _selectedFiles[key];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
              );
              if (result != null && result.files.single.path != null) {
                setState(() {
                  _selectedFiles[key] = File(result.files.single.path!);
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: file != null ? Colors.green : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: file != null ? Colors.green.withOpacity(0.05) : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    file != null ? Icons.check_circle : Icons.upload_file,
                    color: file != null ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      file != null ? file.path.split('/').last : 'Select PDF or Image',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: file != null ? Colors.green : Colors.black54),
                    ),
                  ),
                  if (file != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _selectedFiles.remove(key)),
                    ),
                ],
              ),
            ),
          ),
          if (required && _submitting && file == null)
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 12),
              child: Text('This document is required', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // Basic validation for text fields
    if (!_formKey.currentState!.validate()) return;
    
    // Validate required files
    bool filesMissing = false;
    switch (widget.serviceName) {
      case 'Birth Certificate':
        if (_selectedFiles['id_doc'] == null) filesMissing = true;
        break;
      case 'Passport':
        if (_selectedFiles['nic_doc'] == null || _selectedFiles['bc_doc'] == null || _selectedFiles['studio_doc'] == null) filesMissing = true;
        break;
      case 'NIC':
        if (_selectedFiles['gn_form_doc'] == null || _selectedFiles['bc_doc'] == null || _selectedFiles['studio_doc'] == null || _selectedFiles['ds_cert_doc'] == null) filesMissing = true;
        break;
      case 'Driving License':
        if (_selectedFiles['medical_doc'] == null || _selectedFiles['bc_doc'] == null) filesMissing = true;
        break;
    }

    if (filesMissing) {
      setState(() => _submitting = true); // To trigger error messages
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents.')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _submitting = true);

    try {
      final userId = AuthService.currentUser!.id;
      final finalFormData = Map<String, dynamic>.from(_formData);

      // Upload all selected files
      for (var entry in _selectedFiles.entries) {
        final path = await StorageService.uploadDocument(entry.value, userId);
        finalFormData[entry.key] = path;
      }

      final app = ServiceApplication(
        id: '', // Generated by DB
        userId: userId,
        serviceType: widget.serviceName,
        formData: finalFormData,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await ServiceApplicationService.submitApplication(app);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Complete the form below and upload the required documents (PDF or Image).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ..._buildFormFields(),
              const SizedBox(height: 32),
              LoadingButton(
                label: 'Submit Application',
                isLoading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

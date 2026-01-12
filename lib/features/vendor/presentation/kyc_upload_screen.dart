import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_theme.dart';
import '../data/vendor_provider.dart';
import '../data/vendor_model.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Document types based on your DB enum: 'pan_card', 'aadhar_card', 'gst_certificate'
  String _selectedDocType = 'pan_card';
  final _documentNumberController = TextEditingController();
  File? _selectedFile;
  bool _isLoading = false;

  final List<Map<String, String>> _documentTypes = [
    {'value': 'pan_card', 'label': 'PAN Card'},
    {'value': 'aadhar_card', 'label': 'Aadhar Card'},
    {'value': 'gst_certificate', 'label': 'GST Certificate'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().fetchDocuments();
    });
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedFile = File(picked.path));
      }
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a document image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<VendorProvider>();
    final success = await provider.uploadDocument(
      documentType: _selectedDocType,
      documentNumber: _documentNumberController.text.trim(),
      file: _selectedFile!,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _documentNumberController.clear();
      setState(() => _selectedFile = null);
      _loadDocuments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to upload document'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Documents'),
      ),
      body: Consumer<VendorProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 20),
                _buildUploadForm(),
                const SizedBox(height: 24),
                _buildUploadedDocuments(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KYC Verification',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  'Upload your documents for verification. Once approved, you can start selling.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload New Document',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Document Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedDocType,
              decoration: InputDecoration(
                labelText: 'Document Type',
                prefixIcon: const Icon(Icons.description_outlined,
                    color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _documentTypes.map((doc) {
                return DropdownMenuItem(
                  value: doc['value'],
                  child: Text(doc['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedDocType = value);
              },
            ),
            const SizedBox(height: 16),

            // Document Number
            TextFormField(
              controller: _documentNumberController,
              decoration: InputDecoration(
                labelText: 'Document Number',
                hintText: _getDocumentHint(),
                prefixIcon: const Icon(Icons.numbers, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter document number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // File Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppColors.success
                        : AppColors.border,
                    width: _selectedFile != null ? 2 : 1,
                  ),
                ),
                child: _selectedFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(
                              _selectedFile!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 40, color: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to upload document',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'JPG, PNG (Max 5MB)',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Upload Document',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDocumentHint() {
    switch (_selectedDocType) {
      case 'pan_card':
        return 'e.g., ABCDE1234F';
      case 'aadhar_card':
        return 'e.g., 1234 5678 9012';
      case 'gst_certificate':
        return 'e.g., 22AAAAA0000A1Z5';
      default:
        return 'Enter document number';
    }
  }

  Widget _buildUploadedDocuments(VendorProvider provider) {
    if (provider.isLoading && provider.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uploaded Documents',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (provider.documents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open,
                      size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 8),
                  Text(
                    'No documents uploaded yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ...provider.documents.map((doc) => _DocumentCard(document: doc)),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final VendorDocument document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getStatusColor().withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getDocIcon(), color: _getStatusColor()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDocLabel(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  document.documentNumber ?? 'No number',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  String _getDocLabel() {
    switch (document.documentType) {
      case 'pan_card':
        return 'PAN Card';
      case 'aadhar_card':
        return 'Aadhar Card';
      case 'gst_certificate':
        return 'GST Certificate';
      default:
        return document.documentType;
    }
  }

  IconData _getDocIcon() {
    switch (document.documentType) {
      case 'pan_card':
        return Icons.credit_card;
      case 'aadhar_card':
        return Icons.badge;
      case 'gst_certificate':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getStatusColor() {
    switch (document.status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        document.status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(),
        ),
      ),
    );
  }
}

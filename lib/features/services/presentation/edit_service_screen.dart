import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_theme.dart';
import '../../categories/data/category_provider.dart';
import '../data/service_provider.dart';
import '../data/service_model.dart';

class EditServiceScreen extends StatefulWidget {
  final Service service;

  const EditServiceScreen({super.key, required this.service});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;

  int? _selectedCategoryId;
  String _priceType = 'fixed';
  final List<File> _newImages = [];
  final List<String> _existingImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _descriptionController =
        TextEditingController(text: widget.service.description);
    _priceController =
        TextEditingController(text: widget.service.price.toStringAsFixed(0));
    _durationController =
        TextEditingController(text: widget.service.duration ?? '');
    _selectedCategoryId = widget.service.categoryId;
    _existingImages.addAll(widget.service.images);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images.map((xFile) => File(xFile.path)));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ServiceProvider>();
    final success = await provider.updateService(widget.service.id, {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category_id': _selectedCategoryId,
      'price': double.parse(_priceController.text),
      'price_type': _priceType,
      'duration':
          _durationController.text.isNotEmpty ? _durationController.text : null,
    });

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Service updated successfully'),
            backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.error ?? 'Failed to update service'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Service'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildPricingSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Update Service',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Images',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._existingImages.map((url) => _buildImageTile(networkUrl: url)),
              ..._newImages.map((file) => _buildImageTile(file: file)),
              _buildAddImageButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile({String? networkUrl, File? file}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: networkUrl != null
                ? Image.network(networkUrl,
                    width: 100, height: 100, fit: BoxFit.cover)
                : Image.file(file!, width: 100, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (networkUrl != null) {
                    _existingImages.remove(networkUrl);
                  } else {
                    _newImages.remove(file);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: _pickImages,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: AppColors.textSecondary),
            SizedBox(height: 4),
            Text('Add',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic Information',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        _buildTextField(_nameController, 'Service Name',
            validator: (v) => v?.isEmpty == true ? 'Required' : null),
        const SizedBox(height: 12),
        Consumer<CategoryProvider>(
          builder: (context, categoryProvider, _) {
            return DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'Category',
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: categoryProvider.categories.map((cat) {
                return DropdownMenuItem(value: cat.id, child: Text(cat.name));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategoryId = value),
              validator: (v) => v == null ? 'Required' : null,
            );
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(_descriptionController, 'Description',
            maxLines: 4,
            validator: (v) => v?.isEmpty == true ? 'Required' : null),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pricing',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'fixed',
                groupValue: _priceType,
                onChanged: (v) => setState(() => _priceType = v!),
                title: const Text('Fixed Price'),
                subtitle: const Text('Set a fixed price for this service'),
                activeColor: AppColors.secondary,
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                value: 'hourly',
                groupValue: _priceType,
                onChanged: (v) => setState(() => _priceType = v!),
                title: const Text('Hourly Rate'),
                subtitle: const Text('Charge per hour'),
                activeColor: AppColors.secondary,
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                value: 'quote',
                groupValue: _priceType,
                onChanged: (v) => setState(() => _priceType = v!),
                title: const Text('Request Quote'),
                subtitle: const Text('Customer requests a quote'),
                activeColor: AppColors.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _priceController,
                _priceType == 'quote' ? 'Starting Price (₹)' : 'Price (₹)',
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: _buildTextField(
                    _durationController, 'Duration (Optional)')),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.secondary, width: 2)),
      ),
    );
  }
}

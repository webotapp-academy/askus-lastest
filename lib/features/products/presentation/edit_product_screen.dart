import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_theme.dart';
import '../../categories/data/category_provider.dart';
import '../data/product_provider.dart';
import '../data/product_model.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _comparePriceController;
  late TextEditingController _stockController;
  late TextEditingController _skuController;

  int? _selectedCategoryId;
  String _selectedStatus = 'active';
  final List<File> _newImages = [];
  final List<String> _existingImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _comparePriceController = TextEditingController(
      text: widget.product.comparePrice?.toStringAsFixed(0) ?? '',
    );
    _stockController =
        TextEditingController(text: widget.product.stock.toString());
    _skuController = TextEditingController(text: widget.product.sku ?? '');
    _selectedCategoryId = widget.product.categoryId;
    _selectedStatus = widget.product.status;
    _existingImages.addAll(widget.product.images);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
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

    final provider = context.read<ProductProvider>();
    final success = await provider.updateProduct(widget.product.id, {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category_id': _selectedCategoryId,
      'price': double.parse(_priceController.text),
      'compare_price': _comparePriceController.text.isNotEmpty
          ? double.parse(_comparePriceController.text)
          : null,
      'stock': int.parse(_stockController.text),
      'sku': _skuController.text.isNotEmpty ? _skuController.text : null,
      'status': _selectedStatus,
    });

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.error ?? 'Failed to update product'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
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
              const SizedBox(height: 24),
              _buildInventorySection(),
              const SizedBox(height: 24),
              _buildStatusSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                      : const Text('Update Product',
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
        const Text('Product Images',
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
          borderRadius: BorderRadius.circular(8),
        ),
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
        _buildTextField(_nameController, 'Product Name',
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
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _priceController,
                'Selling Price (₹)',
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _comparePriceController,
                'MRP (Optional)',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inventory',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _stockController,
                'Stock Quantity',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(_skuController, 'SKU (Optional)'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildStatusOption('active', 'Active',
                  'Product is visible and can be purchased', AppColors.success),
              const Divider(height: 1),
              _buildStatusOption('inactive', 'Inactive',
                  'Product is hidden from customers', AppColors.warning),
              const Divider(height: 1),
              _buildStatusOption('draft', 'Draft',
                  'Product is not published yet', AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOption(
      String value, String title, String subtitle, Color color) {
    final isSelected = _selectedStatus == value;
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedStatus,
      onChanged: (v) => setState(() => _selectedStatus = v!),
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      activeColor: AppColors.primary,
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
            borderSide: BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

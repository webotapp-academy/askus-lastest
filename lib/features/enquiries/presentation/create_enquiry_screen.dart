import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../data/enquiry_provider.dart';

class CreateEnquiryScreen extends StatefulWidget {
  final String type;
  final int itemId;
  final String itemName;
  final int vendorId;

  const CreateEnquiryScreen({
    super.key,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.vendorId,
  });

  @override
  State<CreateEnquiryScreen> createState() => _CreateEnquiryScreenState();
}

class _CreateEnquiryScreenState extends State<CreateEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() => _preferredDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _preferredTime = time);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<EnquiryProvider>();
    final success = await provider.createEnquiry(
      type: widget.type,
      itemId: widget.itemId,
      vendorId: widget.vendorId,
      message: _messageController.text.trim(),
      preferredDate: _preferredDate?.toString().split(' ').first,
      preferredTime: _preferredTime?.format(context),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry sent successfully'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to send enquiry'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Enquiry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.type == 'product' ? Icons.shopping_bag : Icons.build,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.itemName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            Text(
                              widget.type == 'product' ? 'Product' : 'Service',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Your Message', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _messageController,
                label: 'Describe your requirement...',
                maxLines: 5,
                validator: (v) => v?.isEmpty == true ? 'Please enter a message' : null,
              ),
              const SizedBox(height: 24),
              const Text('Preferred Schedule (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(
                              _preferredDate != null
                                  ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'
                                  : 'Select Date',
                              style: TextStyle(
                                color: _preferredDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(
                              _preferredTime != null
                                  ? _preferredTime!.format(context)
                                  : 'Select Time',
                              style: TextStyle(
                                color: _preferredTime != null ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Send Enquiry',
                  icon: Icons.send,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

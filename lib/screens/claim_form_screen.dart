import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/claim.dart';
import '../providers/claims_provider.dart';

class ClaimFormScreen extends StatefulWidget {
  final String? claimId; // null for new claim, id for editing

  const ClaimFormScreen({super.key, this.claimId});

  @override
  State<ClaimFormScreen> createState() => _ClaimFormScreenState();
}

class _ClaimFormScreenState extends State<ClaimFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  late TextEditingController _patientNameController;
  late TextEditingController _patientIdController;
  late TextEditingController _insuranceProviderController;
  late TextEditingController _policyNumberController;
  late TextEditingController _diagnosisController;
  late TextEditingController _notesController;

  DateTime _admissionDate = DateTime.now();
  DateTime? _dischargeDate;

  bool get isEditing => widget.claimId != null;

  @override
  void initState() {
    super.initState();
    _patientNameController = TextEditingController();
    _patientIdController = TextEditingController();
    _insuranceProviderController = TextEditingController();
    _policyNumberController = TextEditingController();
    _diagnosisController = TextEditingController();
    _notesController = TextEditingController();

    // If editing, load existing data
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingClaim();
      });
    }
  }

  void _loadExistingClaim() {
    final provider = context.read<ClaimsProvider>();
    final claim = provider.getClaimById(widget.claimId!);
    if (claim != null) {
      setState(() {
        _patientNameController.text = claim.patientName;
        _patientIdController.text = claim.patientId;
        _insuranceProviderController.text = claim.insuranceProvider;
        _policyNumberController.text = claim.policyNumber;
        _diagnosisController.text = claim.diagnosis;
        _notesController.text = claim.notes ?? '';
        _admissionDate = claim.admissionDate;
        _dischargeDate = claim.dischargeDate;
      });
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientIdController.dispose();
    _insuranceProviderController.dispose();
    _policyNumberController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Claim' : 'New Claim')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient Information Section
                    _buildSectionHeader('Patient Information'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _patientNameController,
                      label: 'Patient Name',
                      hint: 'Enter full name',
                      icon: Icons.person_outline,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Patient name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _patientIdController,
                      label: 'Patient ID',
                      hint: 'Hospital ID or MRN',
                      icon: Icons.badge_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Patient ID is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Insurance Information Section
                    _buildSectionHeader('Insurance Details'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _insuranceProviderController,
                      label: 'Insurance Provider',
                      hint: 'e.g., HDFC Ergo, Star Health',
                      icon: Icons.business_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Insurance provider is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _policyNumberController,
                      label: 'Policy Number',
                      hint: 'Insurance policy number',
                      icon: Icons.numbers,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Policy number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Hospitalization Details Section
                    _buildSectionHeader('Hospitalization Details'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _diagnosisController,
                      label: 'Diagnosis / Treatment',
                      hint: 'Primary diagnosis or procedure',
                      icon: Icons.medical_services_outlined,
                      maxLines: 2,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Diagnosis is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Admission Date',
                            date: _admissionDate,
                            onTap: () => _selectDate(isAdmission: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            label: 'Discharge Date',
                            date: _dischargeDate,
                            hint: 'Optional',
                            onTap: () => _selectDate(isAdmission: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Notes Section
                    _buildSectionHeader('Additional Notes'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _notesController,
                      label: 'Notes',
                      hint: 'Any additional information...',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                      required: false,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    FilledButton.icon(
                      onPressed: _submitForm,
                      icon: Icon(isEditing ? Icons.save : Icons.add),
                      label: Text(isEditing ? 'Update Claim' : 'Create Claim'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    bool required = true,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator:
          validator ??
          (required
              ? (val) => val == null || val.trim().isEmpty
                    ? '$label is required'
                    : null
              : null),
    );
  }

  Widget _buildDateField({
    required String label,
    DateTime? date,
    String? hint,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? dateFormat.format(date) : (hint ?? 'Select date'),
          style: TextStyle(color: date != null ? null : Colors.grey[600]),
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isAdmission}) async {
    final initialDate = isAdmission
        ? _admissionDate
        : (_dischargeDate ?? _admissionDate);
    final firstDate = isAdmission ? DateTime(2020) : _admissionDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        if (isAdmission) {
          _admissionDate = picked;
          // Reset discharge if it's before new admission date
          if (_dischargeDate != null && _dischargeDate!.isBefore(picked)) {
            _dischargeDate = null;
          }
        } else {
          _dischargeDate = picked;
        }
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ClaimsProvider>();

    if (isEditing) {
      // Update existing claim
      final existingClaim = provider.getClaimById(widget.claimId!);
      if (existingClaim != null) {
        final updatedClaim = existingClaim.copyWith(
          patientName: _patientNameController.text.trim(),
          patientId: _patientIdController.text.trim(),
          insuranceProvider: _insuranceProviderController.text.trim(),
          policyNumber: _policyNumberController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
          admissionDate: _admissionDate,
          dischargeDate: _dischargeDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        provider.updateClaim(updatedClaim);
      }
    } else {
      // Create new claim
      final newClaim = Claim(
        patientName: _patientNameController.text.trim(),
        patientId: _patientIdController.text.trim(),
        insuranceProvider: _insuranceProviderController.text.trim(),
        policyNumber: _policyNumberController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        admissionDate: _admissionDate,
        dischargeDate: _dischargeDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      provider.addClaim(newClaim);
    }

    setState(() => _isLoading = false);

    // Show success message and go back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? 'Claim updated successfully'
              : 'Claim created successfully',
        ),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}

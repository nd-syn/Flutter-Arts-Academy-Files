import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/services/database_helper.dart';
import 'package:arts_academy/services/school_service.dart';
import 'package:arts_academy/utils/constants.dart';
import 'package:arts_academy/utils/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:form_field_validator/form_field_validator.dart';

class EditStudentScreen extends StatefulWidget {
  final Student student;

  const EditStudentScreen({super.key, required this.student});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _guardianNameController;
  late TextEditingController _guardianPhoneController;
  late TextEditingController _studentPhoneController;
  late TextEditingController _feesController;
  late TextEditingController _addressController;
  
  late String _selectedClass;
  late String _selectedSchool;
  late String _selectedVersion;
  late List<String> _selectedSubjects;
  List<String> _schoolOptions = [];
  DateTime? _admissionDate;
  DateTime? _dob;
  Uint8List? _profileImage;
  bool _isLoading = false;
  bool _isLoadingSchools = true;
  
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SchoolService _schoolService = SchoolService.instance;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoadingSchools = true;
    });

    try {
      final schools = await _schoolService.getAllSchools();
      setState(() {
        _schoolOptions = schools.map((school) => school.name).toList();
        // Make sure the current school is still valid or reset to first option
        if (_schoolOptions.isNotEmpty && !_schoolOptions.contains(_selectedSchool)) {
          _selectedSchool = _schoolOptions.first;
        }
        _isLoadingSchools = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSchools = false;
      });
      _showErrorSnackBar('Failed to load schools: $e');
    }
  }

  void _initializeControllers() {
    // Initialize text controllers with student data
    _nameController = TextEditingController(text: widget.student.name);
    _guardianNameController = TextEditingController(text: widget.student.guardianName);
    _guardianPhoneController = TextEditingController(text: widget.student.guardianPhone);
    _studentPhoneController = TextEditingController(text: widget.student.studentPhone ?? '');
    _feesController = TextEditingController(text: widget.student.fees.toString());
    _addressController = TextEditingController(text: widget.student.address ?? '');
    
    // Initialize other fields
    _selectedClass = widget.student.studentClass;
    _selectedSchool = widget.student.school;
    _selectedVersion = widget.student.version;
    _selectedSubjects = List.from(widget.student.subjects);
    _admissionDate = widget.student.admissionDate;
    _dob = widget.student.dob;
    _profileImage = widget.student.profilePic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _studentPhoneController.dispose();
    _feesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        setState(() {
          _profileImage = imageBytes;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isAdmissionDate) async {
    final DateTime currentDate = DateTime.now();
    final DateTime initialDate = isAdmissionDate 
        ? _admissionDate ?? currentDate 
        : _dob ?? currentDate.subtract(const Duration(days: 365 * 10));
    final DateTime firstDate = isAdmissionDate 
        ? DateTime(currentDate.year - 2, 1) 
        : DateTime(currentDate.year - 30, 1);
    final DateTime lastDate = isAdmissionDate 
        ? currentDate.add(const Duration(days: 30)) 
        : currentDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isAdmissionDate) {
          _admissionDate = picked;
        } else {
          _dob = picked;
        }
      });
    }
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubjects.isEmpty) {
      _showErrorSnackBar('Please select at least one subject');
      return;
    }

    // Ensure dates are not null before updating student
    if (_admissionDate == null || _dob == null) {
      _showErrorSnackBar('Please select both admission date and date of birth');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedStudent = widget.student.copyWith(
        name: _nameController.text.trim(),
        studentClass: _selectedClass,
        school: _selectedSchool,
        version: _selectedVersion,
        guardianName: _guardianNameController.text.trim(),
        guardianPhone: _guardianPhoneController.text.trim(),
        studentPhone: _studentPhoneController.text.trim(),
        subjects: _selectedSubjects,
        fees: double.parse(_feesController.text.trim()),
        address: _addressController.text.trim(),
        admissionDate: _admissionDate!,
        dob: _dob!,
        profilePic: _profileImage, // Uint8List type for profile picture
      );

      await _databaseHelper.updateStudent(updatedStudent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedStudent.name} updated successfully'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to update student: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Edit Student',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImagePicker(),
            const SizedBox(height: 24),
            _buildSectionTitle('Personal Information'),
            _buildTextFormField(
              controller: _nameController,
              label: 'Student Name',
              hint: 'Enter student name',
              icon: Icons.person,
              validator: RequiredValidator(errorText: 'Student name is required'),
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Class',
              value: _selectedClass,
              items: AppConstants.classOptions,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedClass = value;
                  });
                }
              },
              icon: Icons.school,
            ),
            const SizedBox(height: 16),
            _isLoadingSchools
                ? Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Row(
                        children: [
                          SizedBox(width: 16),
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading schools...'),
                        ],
                      ),
                    ),
                  )
                : _schoolOptions.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No schools available. Add schools from Overview tab.',
                                style: TextStyle(color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildDropdownField(
                        label: 'School',
                        value: _selectedSchool,
                        items: _schoolOptions,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSchool = value;
                            });
                          }
                        },
                        icon: Icons.business,
                      ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Version',
              value: _selectedVersion,
              items: AppConstants.versionOptions,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedVersion = value;
                  });
                }
              },
              icon: Icons.language,
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Date of Birth',
              value: _dob,
              onTap: () => _selectDate(context, false),
              icon: Icons.cake,
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Admission Date',
              value: _admissionDate,
              onTap: () => _selectDate(context, true),
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Contact Information'),
            _buildTextFormField(
              controller: _guardianNameController,
              label: 'Guardian Name',
              hint: 'Enter guardian name',
              icon: Icons.person_outline,
              validator: RequiredValidator(errorText: 'Guardian name is required'),
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _guardianPhoneController,
              label: 'Guardian Phone',
              hint: 'Enter guardian phone number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: MultiValidator([
                RequiredValidator(errorText: 'Guardian phone is required'),
                PatternValidator(r'^[0-9]{10}$', errorText: 'Enter a valid 10-digit phone number'),
              ]),
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _studentPhoneController,
              label: 'Student Phone (Optional)',
              hint: 'Enter student phone number',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              validator: PatternValidator(r'^[0-9]{10}$|^$', errorText: 'Enter a valid 10-digit phone number'),
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _addressController,
              label: 'Address',
              hint: 'Enter address',
              icon: Icons.home,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Academic Information'),
            const SizedBox(height: 8),
            _buildSubjectsSelector(),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _feesController,
              label: 'Fees (₹)',
              hint: 'Enter fees amount',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
              validator: MultiValidator([
                RequiredValidator(errorText: 'Fees amount is required'),
                PatternValidator(r'^\d+(\.\d{1,2})?$', errorText: 'Enter a valid amount'),
              ]),
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Hero(
              tag: 'student_profile_${widget.student.id}',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                child: _profileImage != null && _profileImage!.isNotEmpty
                    ? ClipOval(
                        child: Image.memory(
                          _profileImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.student.name.isNotEmpty ? widget.student.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Change Profile Photo',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null ? DateFormat('dd MMM yyyy').format(value) : 'Select Date',
              style: TextStyle(
                color: value != null ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subjects',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.subjectOptions.map((subject) {
            final isSelected = _selectedSubjects.contains(subject);
            return FilterChip(
              label: Text(subject),
              selected: isSelected,
              onSelected: (_) => _toggleSubject(subject),
              backgroundColor: AppTheme.cardBackground,
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedSubjects.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Please select at least one subject',
              style: TextStyle(
                color: AppTheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _updateStudent,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Update Student',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
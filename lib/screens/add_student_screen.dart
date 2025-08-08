import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/services/database_helper.dart';
import 'package:arts_academy/services/school_service.dart';
import 'package:arts_academy/utils/constants.dart';
import 'package:arts_academy/utils/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  final _feesController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedClass = AppConstants.classOptions.first;
  String _selectedSchool = '';
  String _selectedVersion = AppConstants.versionOptions.first;
  final List<String> _selectedSubjects = [];
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
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoadingSchools = true;
    });

    try {
      final schools = await _schoolService.getAllSchools();
      if (mounted) {
        setState(() {
          _schoolOptions = schools.map((school) => school.name).toList();
          if (_schoolOptions.isNotEmpty) {
            _selectedSchool = _schoolOptions.first;
          }
          _isLoadingSchools = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSchools = false;
        });
        _showErrorSnackBar('Failed to load schools: ${e.toString()}');
      }
    }
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
    final DateTime initialDate = isAdmissionDate ? currentDate : currentDate.subtract(const Duration(days: 365 * 10));
    // Remove date restrictions - allow any year selection
    final DateTime firstDate = DateTime(1900, 1, 1); // Allow dates from 1900
    final DateTime lastDate = DateTime(2100, 12, 31); // Allow dates up to 2100

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

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubjects.isEmpty) {
      _showErrorSnackBar('Please select at least one subject');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure dates are not null before creating student
      if (_admissionDate == null || _dob == null) {
        _showErrorSnackBar('Please select both admission date and date of birth');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final student = Student(
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
        profilePic: _profileImage,
      );

      await _databaseHelper.insertStudent(student);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.name} added successfully'),
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
      _showErrorSnackBar('Failed to save student: $e');
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            boxShadow: AppTheme.softShadow,
          ),
          child: SafeArea(
            child: AppBar(
              title: AnimatedDefaultTextStyle(
                duration: AppTheme.mediumAnimation,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppTheme.textOnPrimary,
                  fontWeight: FontWeight.w700,
                ),
                child: const Text('Add New Student'),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.textOnPrimary,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back',
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.3, 0.6, 1.0],
            colors: [
              const Color(0xFF667eea), // Academic blue
              const Color(0xFF764ba2), // Deep purple
              const Color(0xFFf093fb), // Soft pink
              const Color(0xFFf5f7fa), // Light background
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.98),
              ],
            ),
          ),
          child: _isLoading
              ? _buildLoadingIndicator()
              : _buildResponsiveForm(context, isSmallScreen),
        ),
      ),
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
            _buildModernSubmitButton(),
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
              child: _profileImage != null
                  ? ClipOval(
                      child: Image.memory(
                        _profileImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add Profile Photo',
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

  // Ultra-smooth loading indicator optimized for 120Hz
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.mediumShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Saving Student...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Responsive form layout that prevents overflow
  Widget _buildResponsiveForm(BuildContext context, bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16.0 : 32.0,
              vertical: 20.0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Animated sections with staggered animations
                AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: AppTheme.mediumAnimation,
                      childAnimationBuilder: (widget) => SlideAnimation(
                        curve: AppTheme.standardCurve,
                        child: FadeInAnimation(
                          curve: AppTheme.standardCurve,
                          child: widget,
                        ),
                      ),
                      children: [
                        _buildModernProfilePicker(isSmallScreen),
                        const SizedBox(height: 32),
                        _buildAnimatedSection(
                          title: 'Personal Information',
                          icon: Icons.person_rounded,
                          children: [
                            _buildModernTextField(
                              controller: _nameController,
                              label: 'Student Name',
                              hint: 'Enter full name',
                              icon: Icons.badge_outlined,
                              validator: RequiredValidator(errorText: 'Name is required'),
                            ),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isVerySmall = constraints.maxWidth < 350;
                                
                                if (isVerySmall) {
                                  return Column(
                                    children: [
                                      _buildModernDropdown(
                                        label: 'Class',
                                        value: _selectedClass,
                                        items: AppConstants.classOptions,
                                        onChanged: (value) => setState(() => _selectedClass = value!),
                                        icon: Icons.school_outlined,
                                      ),
                                      const SizedBox(height: 16),
                                      _isLoadingSchools
                                        ? Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(16),
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
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'No schools available',
                                                          style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Add schools from Overview tab',
                                                      style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : _buildModernDropdown(
                                                label: 'School',
                                                value: _selectedSchool,
                                                items: _schoolOptions,
                                                onChanged: (value) => setState(() => _selectedSchool = value!),
                                                icon: Icons.business_outlined,
                                              ),
                                    ],
                                  );
                                }
                                
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildModernDropdown(
                                        label: 'Class',
                                        value: _selectedClass,
                                        items: AppConstants.classOptions,
                                        onChanged: (value) => setState(() => _selectedClass = value!),
                                        icon: Icons.school_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _isLoadingSchools
                                          ? Container(
                                              height: 60,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.shade300),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                            )
                                          : _schoolOptions.isEmpty
                                              ? Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade50,
                                                    border: Border.all(color: Colors.orange.shade300),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      'No schools\navailable',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                                                    ),
                                                  ),
                                                )
                                              : _buildModernDropdown(
                                                  label: 'School',
                                                  value: _selectedSchool,
                                                  items: _schoolOptions,
                                                  onChanged: (value) => setState(() => _selectedSchool = value!),
                                                  icon: Icons.business_outlined,
                                                ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildModernDropdown(
                              label: 'Language Version',
                              value: _selectedVersion,
                              items: AppConstants.versionOptions,
                              onChanged: (value) => setState(() => _selectedVersion = value!),
                              icon: Icons.language_rounded,
                            ),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isVerySmall = constraints.maxWidth < 400;
                                
                                if (isVerySmall) {
                                  return Column(
                                    children: [
                                      _buildModernDateField(
                                        label: 'Date of Birth',
                                        value: _dob,
                                        onTap: () => _selectDate(context, false),
                                        icon: Icons.cake_outlined,
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildModernDateField(
                                        label: 'Admission Date',
                                        value: _admissionDate,
                                        onTap: () => _selectDate(context, true),
                                        icon: Icons.event_available_outlined,
                                        isRequired: true,
                                      ),
                                    ],
                                  );
                                }
                                
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildModernDateField(
                                        label: 'Date of Birth',
                                        value: _dob,
                                        onTap: () => _selectDate(context, false),
                                        icon: Icons.cake_outlined,
                                        isRequired: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildModernDateField(
                                        label: 'Admission Date',
                                        value: _admissionDate,
                                        onTap: () => _selectDate(context, true),
                                        icon: Icons.event_available_outlined,
                                        isRequired: true,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildAnimatedSection(
                          title: 'Contact Information',
                          icon: Icons.contact_phone_rounded,
                          children: [
                            _buildModernTextField(
                              controller: _guardianNameController,
                              label: 'Guardian Name',
                              hint: 'Parent/Guardian full name',
                              icon: Icons.family_restroom_outlined,
                              validator: RequiredValidator(errorText: 'Guardian name is required'),
                            ),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isVerySmall = constraints.maxWidth < 400;
                                
                                if (isVerySmall) {
                                  return Column(
                                    children: [
                                      _buildModernTextField(
                                        controller: _guardianPhoneController,
                                        label: 'Guardian Phone',
                                        hint: 'Primary contact',
                                        icon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                        validator: MultiValidator([
                                          RequiredValidator(errorText: 'Phone is required'),
                                          PatternValidator(r'^[0-9]{10}$', errorText: 'Invalid phone number'),
                                        ]),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildModernTextField(
                                        controller: _studentPhoneController,
                                        label: 'Student Phone',
                                        hint: 'Optional',
                                        icon: Icons.smartphone_outlined,
                                        keyboardType: TextInputType.phone,
                                        validator: PatternValidator(r'^[0-9]{10}$|^$', errorText: 'Invalid phone'),
                                        isRequired: false,
                                      ),
                                    ],
                                  );
                                }
                                
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildModernTextField(
                                        controller: _guardianPhoneController,
                                        label: 'Guardian Phone',
                                        hint: 'Primary contact',
                                        icon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                        validator: MultiValidator([
                                          RequiredValidator(errorText: 'Phone is required'),
                                          PatternValidator(r'^[0-9]{10}$', errorText: 'Invalid phone number'),
                                        ]),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildModernTextField(
                                        controller: _studentPhoneController,
                                        label: 'Student Phone',
                                        hint: 'Optional',
                                        icon: Icons.smartphone_outlined,
                                        keyboardType: TextInputType.phone,
                                        validator: PatternValidator(r'^[0-9]{10}$|^$', errorText: 'Invalid phone'),
                                        isRequired: false,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildModernTextField(
                              controller: _addressController,
                              label: 'Address',
                              hint: 'Complete residential address',
                              icon: Icons.home_outlined,
                              maxLines: 3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildAnimatedSection(
                          title: 'Academic Information',
                          icon: Icons.book_outlined,
                          children: [
                            _buildModernSubjectsSelector(),
                            const SizedBox(height: 20),
                            _buildModernTextField(
                              controller: _feesController,
                              label: 'Monthly Fees (₹)',
                              hint: 'Enter amount',
                              icon: Icons.currency_rupee_outlined,
                              keyboardType: TextInputType.number,
                              validator: MultiValidator([
                                RequiredValidator(errorText: 'Fees amount is required'),
                                PatternValidator(r'^\d+(\.\d{1,2})?$', errorText: 'Invalid amount'),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        _buildModernSubmitButton(),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  // Modern profile image picker with smooth animations
  Widget _buildModernProfilePicker(bool isSmallScreen) {
    final size = isSmallScreen ? 100.0 : 120.0;
    
    return Center(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: AppTheme.mediumAnimation,
            tween: Tween(begin: 0.8, end: 1.0),
            curve: AppTheme.bounceCurve,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _pickImage();
                },
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _profileImage != null 
                        ? null 
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.1),
                              AppTheme.primaryLight.withOpacity(0.05),
                            ],
                          ),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: _profileImage != null
                      ? ClipOval(
                          child: Image.memory(
                            _profileImage!,
                            fit: BoxFit.cover,
                            width: size,
                            height: size,
                          ),
                        )
                      : Icon(
                          Icons.add_a_photo_outlined,
                          size: size * 0.35,
                          color: AppTheme.primaryColor,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _profileImage != null ? 'Tap to change photo' : 'Add profile photo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Animated section container
  Widget _buildAnimatedSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.textOnPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
  
  // Modern text field with smooth animations
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.textLight.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.textLight.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.error,
            width: 1,
          ),
        ),
      ),
    );
  }
  
  // Modern dropdown with smooth animations
  Widget _buildModernDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: '$label *',
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.textLight.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.textLight.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
  
  // Modern date field with animations
  Widget _buildModernDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
    bool isRequired = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value != null 
                ? AppTheme.primaryColor.withOpacity(0.3)
                : AppTheme.textLight.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRequired ? '$label *' : label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null 
                        ? DateFormat('dd MMM yyyy').format(value) 
                        : 'Select Date',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: value != null 
                          ? AppTheme.textPrimary 
                          : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
  
  // Modern subjects selector with animations
  Widget _buildModernSubjectsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subjects *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppConstants.subjectOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final subject = entry.value;
            final isSelected = _selectedSubjects.contains(subject);
            
            return AnimatedContainer(
              duration: AppTheme.fastAnimation,
              curve: AppTheme.standardCurve,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _toggleSubject(subject);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.transparent
                          : AppTheme.textLight.withOpacity(0.2),
                    ),
                    boxShadow: isSelected ? AppTheme.softShadow : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.textOnPrimary,
                          size: 16,
                        ),
                      if (isSelected) const SizedBox(width: 6),
                      Text(
                        subject,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected 
                              ? AppTheme.textOnPrimary 
                              : AppTheme.textPrimary,
                          fontWeight: isSelected 
                              ? FontWeight.w600 
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedSubjects.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Please select at least one subject',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.error,
              ),
            ),
          ),
      ],
    );
  }
  
  // Modern submit button with smooth animations
  Widget _buildModernSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _saveStudent();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.save_rounded,
                  color: AppTheme.textOnPrimary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Save Student',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

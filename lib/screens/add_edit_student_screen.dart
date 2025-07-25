import 'package:flutter/material.dart';
import '../models/student.dart';
import '../db/student_db.dart';
import '../widgets/luxury_button.dart';
import 'dart:io'; // Added for File
import 'package:image_picker/image_picker.dart';
import '../widgets/confirm_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:ui'; // Added for ImageFilter

class AddEditStudentScreen extends StatefulWidget {
  final Student? student;
  final int? index;
  const AddEditStudentScreen({Key? key, this.student, this.index}) : super(key: key);

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _classController;
  late TextEditingController _schoolController;
  late TextEditingController _guardianPhoneController;
  late TextEditingController _studentPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _feesController;
  DateTime? _dob;
  DateTime? _admissionDate;
  String _version = 'english';
  List<String> _subjects = [];
  String? _photoPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<String> _classOptions = [
    '6', '7', '8', '9', '10', '11', '12', 'B.A (Pass)', 'B.A (Honours)'
  ];
  int _focusedField = -1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _classController = TextEditingController(text: widget.student?.className ?? '');
    _schoolController = TextEditingController(text: widget.student?.school ?? '');
    _guardianPhoneController = TextEditingController(text: widget.student?.guardianPhone ?? '');
    _studentPhoneController = TextEditingController(text: widget.student?.studentPhone ?? '');
    _addressController = TextEditingController(text: widget.student?.address ?? '');
    _feesController = TextEditingController(text: widget.student?.fees != null ? widget.student!.fees.toString() : '');
    _dob = widget.student?.dob ?? DateTime.now();
    _version = widget.student?.version ?? 'english';
    _subjects = widget.student?.subjects ?? [];
    _photoPath = widget.student?.photoPath;
    _admissionDate = widget.student?.admissionDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _schoolController.dispose();
    _guardianPhoneController.dispose();
    _studentPhoneController.dispose();
    _addressController.dispose();
    _feesController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'), volume: 0.15);
    } catch (_) {}
  }

  void _saveStudent() async {
    if (_formKey.currentState!.validate() && _dob != null && _admissionDate != null) {
      final confirmed = await showConfirmDialog(
        context: context,
        title: widget.student == null ? 'Add Student' : 'Update Student',
        message: widget.student == null
            ? 'Are you sure you want to add this student?'
            : 'Are you sure you want to save changes to this student?',
        icon: Icons.check_circle_outline,
        confirmText: widget.student == null ? 'Add' : 'Update',
      );
      if (confirmed == true) {
        final student = Student(
          name: _nameController.text.trim(),
          className: _classController.text.trim(),
          school: _schoolController.text.trim(),
          guardianPhone: _guardianPhoneController.text.trim(),
          studentPhone: _studentPhoneController.text.trim(),
          address: _addressController.text.trim(),
          dob: _dob!,
          version: _version,
          subjects: _subjects,
          fees: double.tryParse(_feesController.text.trim()) ?? 0.0,
          photoPath: _photoPath,
          admissionDate: _admissionDate!,
        );
        if (widget.index != null) {
          await StudentDB.updateStudent(widget.index!, student);
        } else {
          await StudentDB.addStudent(student);
        }
        await _playSuccessSound();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 12),
                  Text(widget.student == null ? 'Student added!' : 'Student updated!'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _photoPath = picked.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'Add Student' : 'Edit Student'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Animated gradient background
              Positioned.fill(
                child: Animate(
                  effects: [
                    FadeEffect(duration: 600.ms),
                    ShimmerEffect(duration: 3200.ms, color: Colors.white.withOpacity(0.08)),
                  ],
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade50,
                          Colors.blue.shade50,
                          Colors.teal.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.1, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Profile Preview Card
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nameController,
                        builder: (context, nameValue, _) {
                          if (nameValue.text.isEmpty && _photoPath == null) return SizedBox.shrink();
                          return Card(
                            elevation: 10,
                            margin: const EdgeInsets.only(bottom: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                                child: _photoPath == null ? Icon(Icons.person, size: 28, color: Colors.grey) : null,
                              ),
                              title: Text(nameValue.text.isEmpty ? 'Student Name' : nameValue.text,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(_classController.text.isEmpty ? 'Class' : 'Class: ${_classController.text}'),
                            ),
                          ).animate().fadeIn(duration: 400.ms);
                        },
                      ),
                      // Photo picker at the top, center-aligned
                      const SizedBox(height: 8),
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 54,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                                child: _photoPath == null ? Icon(Icons.person, size: 54, color: Colors.grey) : null,
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Material(
                                color: Theme.of(context).colorScheme.primary,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _pickPhoto,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.camera_alt, color: Colors.white, size: 22),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Personal Info Section
                      _glassCard(
                        context,
                        isWide
                            ? Row(
                                children: [
                                  Expanded(child: _buildNameField(0)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildDOBField(context, 1)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildAdmissionDateField(context, 10)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildNameField(0),
                                  const SizedBox(height: 16),
                                  _buildDOBField(context, 1),
                                  const SizedBox(height: 16),
                                  _buildAdmissionDateField(context, 10),
                                ],
                              ),
                      ),
                      // Contact Section
                      _glassCard(
                        context,
                        isWide
                            ? Row(
                                children: [
                                  Expanded(child: _buildGuardianPhoneField(2)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildStudentPhoneField(3)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildGuardianPhoneField(2),
                                  const SizedBox(height: 16),
                                  _buildStudentPhoneField(3),
                                ],
                              ),
                      ),
                      // Address & School Section
                      _glassCard(
                        context,
                        isWide
                            ? Row(
                                children: [
                                  Expanded(child: _buildAddressField(4)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildSchoolField(5)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildAddressField(4),
                                  const SizedBox(height: 16),
                                  _buildSchoolField(5),
                                ],
                              ),
                      ),
                      // Academic Section
                      _glassCard(
                        context,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            isWide
                                ? Row(
                                    children: [
                                      Expanded(child: _buildClassDropdown(6)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildFeesField(7)),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildClassDropdown(6),
                                      const SizedBox(height: 16),
                                      _buildFeesField(7),
                                    ],
                                  ),
                            const SizedBox(height: 18),
                            _buildVersionField(8),
                            const SizedBox(height: 18),
                            _buildSubjectsField(9),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Sticky submit button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: LuxuryButton(
                    label: widget.student == null ? 'Add Student' : 'Save Changes',
                    onPressed: _saveStudent,
                    icon: widget.student == null ? Icons.person_add : Icons.save,
                  ).animate().scale(duration: 300.ms, curve: Curves.easeInOut),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _glassCard(BuildContext context, Widget child) {
    return Animate(
      effects: [
        FadeEffect(duration: 400.ms),
        MoveEffect(duration: 400.ms, begin: const Offset(0, 30)),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.55),
              Colors.white.withOpacity(0.35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.blue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1.2,
          ),
          backgroundBlendMode: BlendMode.overlay,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField = hasFocus ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
            // No setState here; ValueListenableBuilder handles preview update
          ),
        ),
      );

  Widget _buildClassDropdown(int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField = hasFocus ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: DropdownButtonFormField<String>(
            value: _classOptions.contains(_classController.text) ? _classController.text : null,
            items: _classOptions
                .map((c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                _classController.text = val ?? '';
              });
            },
            decoration: const InputDecoration(
              labelText: 'Class',
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Select class' : null,
          ),
        ),
      );

  Widget _buildDOBField(BuildContext context, int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField = hasFocus ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.date_range),
            title: Text(_dob == null
                ? 'Select Date of Birth'
                : 'DOB: ${_dob!.toLocal().toString().split(' ')[0]}'),
            trailing: ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dob ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dob = picked);
              },
              child: const Text('Pick Date'),
            ),
          ),
        ),
      );

  Widget _buildAdmissionDateField(BuildContext context, int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField = hasFocus ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(_admissionDate == null
                ? 'Select Admission Date'
                : 'Admission Date: ${_admissionDate!.toLocal().toString().split(' ')[0]}'),
            trailing: ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _admissionDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _admissionDate = picked);
              },
              child: const Text('Pick Date'),
            ),
          ),
        ),
      );

  Widget _buildSchoolField(int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField = hasFocus ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: _schoolController,
            decoration: const InputDecoration(
              labelText: 'School',
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Enter school' : null,
          ),
        ),
      );

  Widget _buildGuardianPhoneField(int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField == fieldIndex ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: _guardianPhoneController,
            decoration: const InputDecoration(
              labelText: 'Guardian Phone',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) => value == null || value.isEmpty ? 'Enter guardian phone' : null,
          ),
        ),
      );

  Widget _buildStudentPhoneField(int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField = hasFocus ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: _studentPhoneController,
            decoration: const InputDecoration(
              labelText: 'Student Phone',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ),
      );

  Widget _buildAddressField(int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField = hasFocus ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Enter address' : null,
          ),
        ),
      );

  Widget _buildFeesField(int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField = hasFocus ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: _feesController,
            decoration: const InputDecoration(
              labelText: 'Fees',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) => value == null || value.isEmpty ? 'Enter fees' : null,
          ),
        ),
      );

  Widget _buildVersionField(int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField = hasFocus ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: 'english',
                groupValue: _version,
                onChanged: (val) => setState(() => _version = val!),
              ),
              const Text('English Version'),
              Radio<String>(
                value: 'bengali',
                groupValue: _version,
                onChanged: (val) => setState(() => _version = val!),
              ),
              const Text('Bengali Version'),
            ],
          ),
        ),
      );

  Widget _buildSubjectsField(int fieldIndex) => Focus(
        onFocusChange: (hasFocus) => setState(() => _focusedField = hasFocus ? fieldIndex : -1),
        child: AnimatedContainer(
          duration: 220.ms,
          decoration: BoxDecoration(
            boxShadow: _focusedField == fieldIndex
                ? [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Subjects', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final subject in ['English', 'Bengali', 'Sanskrit', 'History', 'Geography', 'Computer'])
                    FilterChip(
                      label: Text(subject),
                      selected: _subjects.contains(subject),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _subjects.add(subject);
                          } else {
                            _subjects.remove(subject);
                          }
                        });
                      },
                    ),
                ],
              ),
              if (_subjects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _subjects
                      .map((s) => Chip(
                            label: Text(s),
                            onDeleted: () => setState(() => _subjects.remove(s)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );
} 
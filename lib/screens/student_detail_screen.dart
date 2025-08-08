import 'package:flutter/material.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/screens/edit_student_screen.dart';
import 'package:arts_academy/services/database_helper.dart';
import 'package:arts_academy/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Student _student;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
  }

  Future<void> _refreshStudentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedStudent = await _databaseHelper.getStudent(_student.id!);
      if (updatedStudent != null) {
        setState(() {
          _student = updatedStudent;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to refresh student data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: AppBar(
              title: const Text(
                'Student Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditStudentScreen(student: _student),
                      ),
                    );
                    if (result == true) {
                      _refreshStudentData();
                    }
                  },
                  tooltip: 'Edit Student',
                ),
              ],
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
              ? const Center(child: CircularProgressIndicator())
              : _buildStudentDetails(),
        ),
      ),
    );
  }

  Widget _buildStudentDetails() {
    return RefreshIndicator(
      onRefresh: _refreshStudentData,
      color: AppTheme.primaryColor,
      child: AnimationLimiter(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildInfoSection('Personal Information', [
                    _buildInfoRow('Name', _student.name),
                    _buildInfoRow('Class', _student.studentClass),
                    _buildInfoRow('School', _student.school),
                    _buildInfoRow('Version', _student.version),
                    if (_student.dob != null)
                      _buildInfoRow(
                        'Date of Birth',
                        DateFormat('dd MMM yyyy').format(_student.dob!),
                      ),
                    if (_student.admissionDate != null)
                      _buildInfoRow(
                        'Admission Date',
                        DateFormat('dd MMM yyyy').format(_student.admissionDate!),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Contact Information', [
                    _buildInfoRow('Guardian Name', _student.guardianName),
                    _buildInfoRow('Guardian Phone', _student.guardianPhone),
                    if (_student.studentPhone != null && _student.studentPhone!.isNotEmpty)
                      _buildInfoRow('Student Phone', _student.studentPhone!),
                    if (_student.address != null && _student.address!.isNotEmpty)
                      _buildInfoRow('Address', _student.address!),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Academic Information', [
                    _buildInfoRow('Subjects', _student.subjects.join(', ')),
                    _buildInfoRow('Fees', '₹${_student.fees}'),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Hero(
            tag: 'student_profile_${_student.id}',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.2),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _student.profilePic != null && _student.profilePic!.isNotEmpty
                  ? ClipOval(
                      child: Image.memory(
                        _student.profilePic!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildInitialAvatar(),
                      ),
                    )
                  : _buildInitialAvatar(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _student.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${_student.studentClass} • ${_student.school}',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar() {
    return Center(
      child: Text(
        _student.name.isNotEmpty ? _student.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
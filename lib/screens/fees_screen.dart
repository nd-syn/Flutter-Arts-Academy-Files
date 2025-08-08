import 'package:flutter/material.dart';
import 'package:arts_academy/models/fee_model.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/services/database_helper.dart';
import 'package:arts_academy/services/fee_service.dart';
import 'package:arts_academy/utils/theme.dart';
import 'package:arts_academy/screens/student_fees_detail_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FeeService _feeService = FeeService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allStudentsWithFeeStatus = [];
  List<Map<String, dynamic>> _filteredStudentsWithFeeStatus = [];
  Map<String, dynamic>? _feesSummary;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedSortFilter = 'All'; // All, Due, Paid, Upcoming
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _loadFeesData();
  }

  Future<void> _loadFeesData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use the new FeeService to get students with dynamic fee status
      List<Map<String, dynamic>> studentsWithStatus = await _feeService.getAllStudentsWithFeeStatus();
      Map<String, dynamic> summary = await _feeService.getFeesSummary();
      
      setState(() {
        _allStudentsWithFeeStatus = studentsWithStatus;
        _filteredStudentsWithFeeStatus = studentsWithStatus;
        _feesSummary = summary;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load fees data: $e';
      });
    }
  }

  Future<void> _showAddFeeDialog(Student student) async {
    final TextEditingController amountController = TextEditingController();
    String paymentStatus = 'Paid';
    DateTime selectedDate = DateTime.now();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Fee Payment for ${student.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(DateTime.now().year - 1),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppTheme.primaryColor,
                              onPrimary: Colors.white,
                              onSurface: AppTheme.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Payment Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentStatus,
                  decoration: InputDecoration(
                    labelText: 'Payment Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        paymentStatus = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an amount')),
                  );
                  return;
                }
                
                Navigator.pop(context, {
                  'amount': double.parse(amountController.text.trim()),
                  'date': selectedDate,
                  'status': paymentStatus,
                });
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result != null) {
        try {
          final fee = Fee(
            studentId: student.id!,
            amount: result['amount'],
            paymentDate: result['date'],
            paymentMonth: result['date'].month,
            paymentYear: result['date'].year,
            paymentStatus: result['status'],
          );
          
          await _databaseHelper.insertFee(fee);
          _showSuccessSnackBar('Payment added successfully');
          _loadFeesData(); // Refresh the list
        } catch (e) {
          _showErrorSnackBar('Failed to add payment: $e');
        }
      }
    });
  }

  Future<void> _showUpdateFeeDialog(Fee fee, Student student) async {
    final TextEditingController amountController = TextEditingController(text: fee.amount.toString());
    String paymentStatus = fee.paymentStatus;
    DateTime selectedDate = fee.paymentDate ?? DateTime.now();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Fee Payment for ${student.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(DateTime.now().year - 1),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppTheme.primaryColor,
                              onPrimary: Colors.white,
                              onSurface: AppTheme.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Payment Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentStatus,
                  decoration: InputDecoration(
                    labelText: 'Payment Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        paymentStatus = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an amount')),
                  );
                  return;
                }
                
                Navigator.pop(context, {
                  'amount': double.parse(amountController.text.trim()),
                  'date': selectedDate,
                  'status': paymentStatus,
                });
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result != null) {
        try {
          final updatedFee = fee.copyWith(
            amount: result['amount'],
            paymentDate: result['date'],
            paymentMonth: result['date'].month,
            paymentYear: result['date'].year,
            paymentStatus: result['status'],
          );
          
          await _databaseHelper.updateFee(updatedFee);
          _showSuccessSnackBar('Payment updated successfully');
          _loadFeesData(); // Refresh the list
        } catch (e) {
          _showErrorSnackBar('Failed to update payment: $e');
        }
      }
    });
  }

  Future<void> _deleteFee(Fee fee, Student student) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Are you sure you want to delete this payment record for ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _databaseHelper.deleteFee(fee.id!);
        _showSuccessSnackBar('Payment deleted successfully');
        _loadFeesData(); // Refresh the list
      } catch (e) {
        _showErrorSnackBar('Failed to delete payment: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onSortFilterChanged(String filter) {
    setState(() {
      _selectedSortFilter = filter;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allStudentsWithFeeStatus);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final student = item['student'] as Student;
        return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               student.studentClass.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               student.school.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply status filter
    if (_selectedSortFilter != 'All') {
      filtered = filtered.where((item) {
        return item['overallStatus'] == _selectedSortFilter;
      }).toList();
    }
    
    setState(() {
      _filteredStudentsWithFeeStatus = filtered;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.8),
              Colors.white.withOpacity(0.95),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? _buildErrorView()
                : _allStudentsWithFeeStatus.isEmpty
                    ? _buildEmptyView()
                    : Column(
                        children: [
                          _buildSearchAndFilterHeader(),
                          Expanded(child: _buildFeesList()),
                        ],
                      ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFeesData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payment_outlined,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Fee Records Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Add your first fee record by tapping the + button below',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeesList() {
    return RefreshIndicator(
      onRefresh: _loadFeesData,
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _filteredStudentsWithFeeStatus.length,
                itemBuilder: (context, index) {
                  final item = _filteredStudentsWithFeeStatus[index];
                  final student = item['student'] as Student;
                  final status = item['overallStatus'] as String;
                  final totalPaidAmount = item['totalPaidAmount'] as double;
                  final totalPendingAmount = item['totalPendingAmount'] as double;
                  final pendingDueAmount = item['pendingDueAmount'] as double;
                  final totalPaidMonths = item['totalPaidMonths'] as int;
            
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentFeesDetailScreen(
                                  student: student,
                                ),
                              ),
                            ).then((_) => _loadFeesData()); // Refresh data when returning
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.cardBackground,
                                    AppTheme.cardBackground.withOpacity(0.95),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppTheme.textLight.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Profile Avatar (similar to StudentCard)
                                        Hero(
                                          tag: 'student_fees_avatar_${student.id}',
                                          child: Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(18),
                                              gradient: student.profilePic != null 
                                                ? null 
                                                : AppTheme.primaryGradient,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                              image: student.profilePic != null
                                                ? DecorationImage(
                                                    image: MemoryImage(student.profilePic!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                            ),
                                            child: student.profilePic == null
                                              ? Center(
                                                  child: Text(
                                                    student.name.isNotEmpty
                                                      ? student.name[0].toUpperCase()
                                                      : '?',
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.textOnPrimary,
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(18),
                                                    border: Border.all(
                                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Student Information
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.school_outlined,
                                                    size: 14,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${student.studentClass} • ${student.school}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: AppTheme.textSecondary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.payment_outlined,
                                                    size: 14,
                                                    color: AppTheme.accentColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$totalPaidMonths of 12 months paid',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.accentColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Status and Monthly Fee
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            _buildStatusChip(status),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: AppTheme.primaryGradient,
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.currency_rupee_rounded,
                                                    size: 14,
                                                    color: AppTheme.textOnPrimary,
                                                  ),
                                                  Text(
                                                    student.fees.toInt().toString(),
                                                    style: const TextStyle(
                                                      color: AppTheme.textOnPrimary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'monthly',
                                                    style: TextStyle(
                                                      color: AppTheme.textOnPrimary.withOpacity(0.8),
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Payment Summary Row
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: AppTheme.success,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Paid: ₹${totalPaidAmount.toInt()}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.success,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: pendingDueAmount > 0 ? AppTheme.error : Colors.grey.shade400,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Due: ₹${pendingDueAmount.toInt()}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: pendingDueAmount > 0 ? AppTheme.error : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    
    switch (status) {
      case 'Paid':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'Due':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'Upcoming':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'Pending':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    if (_feesSummary == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_rounded,
                color: AppTheme.textOnPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Fee Summary - ${_feesSummary!['currentMonth']} ${_feesSummary!['currentYear']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textOnPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total\nStudents',
                  _feesSummary!['totalStudents'].toString(),
                  Icons.people_rounded,
                  AppTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Students\nwith Dues',
                  _feesSummary!['studentsWithDues'].toString(),
                  Icons.warning_rounded,
                  AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total\nCollected',
                  '₹${(_feesSummary!['totalCollected'] as double).toInt()}',
                  Icons.check_circle_rounded,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total\nDue',
                  '₹${(_feesSummary!['totalDue'] as double).toInt()}',
                  Icons.schedule_rounded,
                  AppTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.textOnPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textOnPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.textOnPrimary,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textOnPrimary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and search action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title and count
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fee Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_filteredStudentsWithFeeStatus.length} of ${_allStudentsWithFeeStatus.length} students',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // Search toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) {
                      _searchController.clear();
                      _onSearchChanged('');
                    }
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isSearchVisible
                        ? AppTheme.primaryColor
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _isSearchVisible
                            ? AppTheme.primaryColor.withOpacity(0.25)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
                    color: _isSearchVisible
                        ? Colors.white
                        : AppTheme.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Search Bar (Animated)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSearchVisible ? 52 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isSearchVisible ? 1.0 : 0.0,
              child: _isSearchVisible
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _searchQuery.isNotEmpty
                              ? AppTheme.primaryColor.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        autofocus: _isSearchVisible,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              Icons.search_rounded,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.textSecondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: AppTheme.textSecondary,
                                      size: 16,
                                    ),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          
          if (_isSearchVisible) const SizedBox(height: 16),
          
          // Filter Tabs
          Container(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFilterTab('All', Icons.apps_rounded, _allStudentsWithFeeStatus.length),
                const SizedBox(width: 12),
                _buildFilterTab('Due', Icons.warning_amber_rounded, 
                  _allStudentsWithFeeStatus.where((item) => item['overallStatus'] == 'Due').length),
                const SizedBox(width: 12),
                _buildFilterTab('Paid', Icons.check_circle_rounded,
                  _allStudentsWithFeeStatus.where((item) => item['overallStatus'] == 'Paid').length),
                const SizedBox(width: 12),
                _buildFilterTab('Upcoming', Icons.access_time_rounded,
                  _allStudentsWithFeeStatus.where((item) => item['overallStatus'] == 'Upcoming').length),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, IconData icon, int count) {
    final bool isSelected = _selectedSortFilter == label;
    
    // Define colors based on filter type and selection state
    Color backgroundColor, textColor, iconColor, countBgColor, countTextColor;
    
    if (isSelected) {
      switch (label) {
        case 'Due':
          backgroundColor = const Color(0xFFFF4757);
          textColor = Colors.white;
          iconColor = Colors.white;
          countBgColor = Colors.white.withOpacity(0.25);
          countTextColor = Colors.white;
          break;
        case 'Paid':
          backgroundColor = const Color(0xFF2ED573);
          textColor = Colors.white;
          iconColor = Colors.white;
          countBgColor = Colors.white.withOpacity(0.25);
          countTextColor = Colors.white;
          break;
        case 'Upcoming':
          backgroundColor = const Color(0xFFFFA726);
          textColor = Colors.white;
          iconColor = Colors.white;
          countBgColor = Colors.white.withOpacity(0.25);
          countTextColor = Colors.white;
          break;
        default: // All
          backgroundColor = AppTheme.primaryColor;
          textColor = Colors.white;
          iconColor = Colors.white;
          countBgColor = Colors.white.withOpacity(0.25);
          countTextColor = Colors.white;
      }
    } else {
      backgroundColor = AppTheme.cardBackground;
      textColor = AppTheme.textSecondary;
      iconColor = AppTheme.textSecondary;
      countBgColor = AppTheme.textSecondary.withOpacity(0.1);
      countTextColor = AppTheme.textSecondary;
    }
    
    return GestureDetector(
      onTap: () => _onSortFilterChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: countBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: countTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/models/fee_model.dart';
import 'package:arts_academy/services/database_helper.dart';
import 'package:arts_academy/utils/theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

class StudentFeesDetailScreen extends StatefulWidget {
  final Student student;

  const StudentFeesDetailScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentFeesDetailScreen> createState() => _StudentFeesDetailScreenState();
}

class _StudentFeesDetailScreenState extends State<StudentFeesDetailScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;

  Map<int, Fee?> _monthlyFees = {};
  bool _isLoading = true;
  int _currentYear = DateTime.now().year;
  double _totalPaid = 0;
  double _totalPending = 0;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMonthlyFees();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyFees() async {
    setState(() => _isLoading = true);

    try {
      final fees = await _databaseHelper.getFeesForStudent(widget.student.id!);
      
      // Initialize all months with null
      _monthlyFees = {for (int i = 1; i <= 12; i++) i: null};
      
      // Fill in the fees data
      double totalPaid = 0;
      for (final fee in fees) {
        if (fee.paymentYear == _currentYear && fee.paymentMonth != null) {
          _monthlyFees[fee.paymentMonth!] = fee;
          if (fee.paymentStatus == 'Paid') {
            totalPaid += fee.amount;
          }
        }
      }

      _totalPaid = totalPaid;
      _totalPending = (widget.student.fees * 12) - totalPaid;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load fees data: $e');
    }
  }

  Future<void> _showAddFeeDialog(int month) async {
    final TextEditingController amountController = TextEditingController(
      text: widget.student.fees.toString(),
    );
    String paymentStatus = 'Paid';
    DateTime selectedDate = DateTime(_currentYear, month, DateTime.now().day);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.payment,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add ${_monthNames[month - 1]} Payment',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      firstDate: DateTime(_currentYear, month, 1),
                      lastDate: DateTime(_currentYear, month + 1, 0),
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
                      setState(() => selectedDate = picked);
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
                    child: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
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
                    prefixIcon: const Icon(Icons.check_circle_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => paymentStatus = value);
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add Payment'),
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result != null) {
        try {
          final fee = Fee(
            studentId: widget.student.id!,
            amount: result['amount'],
            paymentDate: result['date'],
            paymentMonth: result['date'].month,
            paymentYear: result['date'].year,
            paymentStatus: result['status'],
          );

          await _databaseHelper.insertFee(fee);
          _showSuccessSnackBar('Payment added successfully');
          _loadMonthlyFees();
        } catch (e) {
          _showErrorSnackBar('Failed to add payment: $e');
        }
      }
    });
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

  Future<void> _showFeeDetailsDialog(Fee fee) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payment Details',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Month', _monthNames[fee.paymentMonth! - 1]),
              _buildDetailRow('Year', fee.paymentYear.toString()),
              _buildDetailRow('Amount', '₹${NumberFormat('#,##,##0').format(fee.amount.toInt())}'),
              _buildDetailRow('Status', fee.paymentStatus),
              if (fee.paymentDate != null)
                _buildDetailRow('Payment Date', DateFormat('dd MMM, yyyy').format(fee.paymentDate!)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryLight.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Information',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This payment record was created for ${widget.student.name}\'s ${_monthNames[fee.paymentMonth! - 1]} ${fee.paymentYear} fee.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (fee.paymentStatus != 'Paid')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditFeeDialog(fee);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Edit'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditFeeDialog(Fee fee) async {
    final TextEditingController amountController = TextEditingController(
      text: fee.amount.toString(),
    );
    String paymentStatus = fee.paymentStatus;
    DateTime selectedDate = fee.paymentDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Edit ${_monthNames[fee.paymentMonth! - 1]} Payment',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      firstDate: DateTime(fee.paymentYear, fee.paymentMonth!, 1),
                      lastDate: DateTime(fee.paymentYear, fee.paymentMonth! + 1, 0),
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
                      setState(() => selectedDate = picked);
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
                    child: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
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
                    prefixIcon: const Icon(Icons.check_circle_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => paymentStatus = value);
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update Payment'),
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
          _loadMonthlyFees();
        } catch (e) {
          _showErrorSnackBar('Failed to update payment: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.primaryLight.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildSummarySection(),
              _buildMonthlyFeesGrid(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _headerAnimation.value,
            child: FlexibleSpaceBar(
              title: Text(
                '${widget.student.name}\'s Fees',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryLight,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const SizedBox(width: 56), // Account for back button
                        Hero(
                          tag: 'student_avatar_${widget.student.id}',
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white, width: 3),
                              image: widget.student.profilePic != null
                                  ? DecorationImage(
                                      image: MemoryImage(widget.student.profilePic!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              gradient: widget.student.profilePic == null
                                  ? LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.9),
                                        Colors.white.withOpacity(0.7),
                                      ],
                                    )
                                  : null,
                            ),
                            child: widget.student.profilePic == null
                                ? Center(
                                    child: Text(
                                      widget.student.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.student.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.student.studentClass} • ${widget.student.school}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '₹${widget.student.fees.toInt()}/month',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
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
          );
        },
      ),
    );
  }

  Widget _buildSummarySection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _contentAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _contentAnimation.value,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Year $_currentYear Summary',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showYearPicker(),
                        icon: const Icon(Icons.calendar_month),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Paid',
                          amount: _totalPaid,
                          color: AppTheme.success,
                          icon: Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Pending',
                          amount: _totalPending,
                          color: AppTheme.error,
                          icon: Icons.pending,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toInt()}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyFeesGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final month = index + 1;
            final fee = _monthlyFees[month];
            
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                curve: Curves.easeOutBack,
                child: FadeInAnimation(
                  child: _buildMonthCard(month, fee),
                ),
              ),
            );
          },
          childCount: 12,
        ),
      ),
    );
  }

  Widget _buildMonthCard(int month, Fee? fee) {
    final bool isPaid = fee?.paymentStatus == 'Paid';
    final bool isPartial = fee?.paymentStatus == 'Partial';
    final bool isPending = fee == null || fee.paymentStatus == 'Pending';
    final bool isCurrentMonth = DateTime.now().month == month && DateTime.now().year == _currentYear;
    final bool isUpcoming = month > DateTime.now().month && _currentYear == DateTime.now().year;
    final bool isOverdue = month < DateTime.now().month && fee == null && _currentYear == DateTime.now().year;

    Color cardColor;
    Color textColor;
    Color accentColor;
    IconData statusIcon;
    String statusText;
    List<Color> gradientColors;
    
    if (isPaid) {
      cardColor = AppTheme.success;
      textColor = Colors.white;
      accentColor = AppTheme.success;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'PAID';
      gradientColors = [AppTheme.success, AppTheme.success.withOpacity(0.8)];
    } else if (isPartial) {
      cardColor = const Color(0xFFFF8A00);
      textColor = Colors.white;
      accentColor = const Color(0xFFFF8A00);
      statusIcon = Icons.schedule_rounded;
      statusText = 'PARTIAL';
      gradientColors = [const Color(0xFFFF8A00), const Color(0xFFFFB347)];
    } else if (isOverdue) {
      cardColor = AppTheme.error;
      textColor = Colors.white;
      accentColor = AppTheme.error;
      statusIcon = Icons.error_rounded;
      statusText = 'OVERDUE';
      gradientColors = [AppTheme.error, Colors.red.shade400];
    } else if (isCurrentMonth && fee == null) {
      cardColor = const Color(0xFF6366F1);
      textColor = Colors.white;
      accentColor = const Color(0xFF6366F1);
      statusIcon = Icons.access_time_rounded;
      statusText = 'DUE NOW';
      gradientColors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    } else if (isUpcoming) {
      cardColor = Colors.grey.shade100;
      textColor = AppTheme.textSecondary;
      accentColor = AppTheme.textSecondary;
      statusIcon = Icons.upcoming_rounded;
      statusText = 'UPCOMING';
      gradientColors = [Colors.grey.shade50, Colors.grey.shade100];
    } else {
      cardColor = AppTheme.error.withOpacity(0.1);
      textColor = AppTheme.error;
      accentColor = AppTheme.error;
      statusIcon = Icons.pending_rounded;
      statusText = 'PENDING';
      gradientColors = [Colors.red.shade50, Colors.red.shade100];
    }

    return GestureDetector(
      onTap: () => fee == null ? _showAddFeeDialog(month) : _showFeeDetailsDialog(fee),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPaid || isPartial || isOverdue || isCurrentMonth
                ? gradientColors
                : [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isPaid || isPartial || isOverdue || isCurrentMonth
                ? Colors.transparent
                : cardColor.withOpacity(0.3),
            width: isPaid || isPartial || isOverdue || isCurrentMonth ? 0 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isPaid || isPartial || isOverdue || isCurrentMonth
                  ? cardColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: isPaid || isPartial || isOverdue || isCurrentMonth ? 20 : 8,
              offset: const Offset(0, 8),
              spreadRadius: isPaid || isPartial || isOverdue || isCurrentMonth ? 2 : 0,
            ),
            if (isPaid || isPartial || isOverdue || isCurrentMonth)
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
                spreadRadius: 0,
              ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern for paid cards
            if (isPaid)
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            if (isPaid)
              Positioned(
                bottom: -10,
                left: -10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            
            // Card Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with month and status icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _monthNames[month - 1].toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isPaid || isPartial || isOverdue || isCurrentMonth
                                    ? textColor
                                    : AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$_currentYear',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isPaid || isPartial || isOverdue || isCurrentMonth
                                    ? textColor.withOpacity(0.8)
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPaid || isPartial || isOverdue || isCurrentMonth
                              ? Colors.white.withOpacity(0.2)
                              : accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          statusIcon,
                          color: isPaid || isPartial || isOverdue || isCurrentMonth
                              ? Colors.white
                              : accentColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid || isPartial || isOverdue || isCurrentMonth
                          ? Colors.white.withOpacity(0.2)
                          : accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPaid || isPartial || isOverdue || isCurrentMonth
                            ? Colors.white.withOpacity(0.3)
                            : accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPaid || isPartial || isOverdue || isCurrentMonth
                            ? Colors.white
                            : accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Amount and date section
                  if (fee != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${NumberFormat('#,##,##0').format(fee.amount.toInt())}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isPaid || isPartial || isOverdue || isCurrentMonth
                                      ? textColor
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              if (fee.paymentDate != null)
                                Text(
                                  DateFormat('dd MMM, yyyy').format(fee.paymentDate!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isPaid || isPartial || isOverdue || isCurrentMonth
                                        ? textColor.withOpacity(0.8)
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isPaid)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    // Unpaid state
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${NumberFormat('#,##,##0').format(widget.student.fees.toInt())}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrentMonth || isOverdue
                                      ? textColor
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                isUpcoming ? 'Upcoming payment' : 'Payment due',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isCurrentMonth || isOverdue
                                      ? textColor.withOpacity(0.8)
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isUpcoming)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCurrentMonth || isOverdue
                                  ? Colors.white.withOpacity(0.2)
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: isCurrentMonth || isOverdue
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showYearPicker() async {
    final int? selectedYear = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Year'),
        content: SizedBox(
          width: double.minPositive,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            selectedDate: DateTime(_currentYear),
            onChanged: (DateTime dateTime) {
              Navigator.pop(context, dateTime.year);
            },
          ),
        ),
      ),
    );

    if (selectedYear != null && selectedYear != _currentYear) {
      setState(() {
        _currentYear = selectedYear;
      });
      _loadMonthlyFees();
    }
  }
}

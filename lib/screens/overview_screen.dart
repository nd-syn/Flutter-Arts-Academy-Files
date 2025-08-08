import 'package:flutter/material.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/services/fee_service.dart';
import 'package:arts_academy/services/data_import_service.dart';
import 'package:arts_academy/services/data_import_export_service.dart';
import 'package:arts_academy/models/import_result.dart';
import 'package:arts_academy/utils/theme.dart';
import 'package:arts_academy/screens/manage_schools_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final FeeService _feeService = FeeService.instance;
  Map<String, dynamic>? _feesSummary;
  List<Map<String, dynamic>> _monthlyData = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  Future<void> _loadOverviewData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load fees summary and monthly breakdown
      Map<String, dynamic> summary = await _feeService.getFeesSummary();
      List<Map<String, dynamic>> studentsWithStatus = await _feeService.getAllStudentsWithFeeStatus();
      
      // Calculate monthly breakdown
      _monthlyData = _calculateMonthlyBreakdown(studentsWithStatus);
      
      setState(() {
        _feesSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load overview data: $e';
      });
    }
  }

  List<Map<String, dynamic>> _calculateMonthlyBreakdown(List<Map<String, dynamic>> studentsData) {
    // Calculate monthly collection and due amounts
    Map<int, double> monthlyCollected = {};
    Map<int, double> monthlyDue = {};
    
    final currentMonth = DateTime.now().month;
    
    for (var studentData in studentsData) {
      final student = studentData['student'] as Student;
      final monthlyFees = student.fees;
      final monthlyDetails = studentData['monthlyDetails'] as Map<int, Map<String, dynamic>>;
      
      // Process each month's details
      monthlyDetails.forEach((month, details) {
        if (details['paid'] == true) {
          // Month is paid
          monthlyCollected[month] = (monthlyCollected[month] ?? 0) + monthlyFees;
        } else {
          // Month is not paid
          if (month < currentMonth) {
            // Past month - it's due
            monthlyDue[month] = (monthlyDue[month] ?? 0) + monthlyFees;
          }
          // For future months, we don't count them as "due" yet
        }
      });
    }
    
    // Create monthly data list
    List<Map<String, dynamic>> monthlyBreakdown = [];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    for (int i = 1; i <= 12; i++) {
      monthlyBreakdown.add({
        'month': months[i - 1],
        'monthNumber': i,
        'collected': monthlyCollected[i] ?? 0.0,
        'due': monthlyDue[i] ?? 0.0,
        'isCurrent': i == currentMonth,
        'isPast': i < currentMonth,
        'isFuture': i > currentMonth,
      });
    }
    
    return monthlyBreakdown;
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
                : _buildOverviewContent(),
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
            onPressed: _loadOverviewData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewContent() {
    if (_feesSummary == null) {
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
                Icons.dashboard_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add students and fee records to see overview',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOverviewData,
      color: AppTheme.primaryColor,
      child: AnimationLimiter(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Overall Summary Cards
                  AnimationConfiguration.staggeredList(
                    position: 0,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildSummaryCards(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Current Month Highlight
                  AnimationConfiguration.staggeredList(
                    position: 1,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildCurrentMonthCard(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Monthly Breakdown
                  AnimationConfiguration.staggeredList(
                    position: 2,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildMonthlyBreakdown(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Quick Stats
                  AnimationConfiguration.staggeredList(
                    position: 3,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildQuickStats(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Schools Management
                  AnimationConfiguration.staggeredList(
                    position: 4,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildSchoolsManagement(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Backup Card
                  AnimationConfiguration.staggeredList(
                    position: 5,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildBackupCard(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Data Management
                  AnimationConfiguration.staggeredList(
                    position: 6,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildDataManagement(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom navigation
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
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
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Financial Overview - ${_feesSummary!['currentMonth']} ${_feesSummary!['currentYear']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textOnPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Main stats grid
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.textOnPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
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
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textOnPrimary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthCard() {
    final currentMonth = DateTime.now().month;
    final currentMonthData = _monthlyData.firstWhere(
      (data) => data['monthNumber'] == currentMonth,
      orElse: () => {'month': 'N/A', 'collected': 0.0, 'due': 0.0},
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentColor,
            AppTheme.accentColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: AppTheme.textOnPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentMonthData['month']} ${DateTime.now().year}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Collected',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textOnPrimary.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            '₹${(currentMonthData['collected'] as double).toInt()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textOnPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textOnPrimary.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            '₹${(currentMonthData['due'] as double).toInt()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textOnPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  Icons.bar_chart_rounded,
                  color: AppTheme.textOnPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Monthly Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Monthly bars
          ..._monthlyData.map((monthData) => _buildMonthlyBar(monthData)),
        ],
      ),
    );
  }

  Widget _buildMonthlyBar(Map<String, dynamic> monthData) {
    final collected = monthData['collected'] as double;
    final due = monthData['due'] as double;
    final total = collected + due;
    final maxAmount = _monthlyData.map((m) => (m['collected'] + m['due']) as double).fold(0.0, (a, b) => a > b ? a : b);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthData['month'],
                style: TextStyle(
                  fontWeight: monthData['isCurrent'] ? FontWeight.bold : FontWeight.w500,
                  color: monthData['isCurrent'] ? AppTheme.primaryColor : AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              Text(
                '₹${total.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade200,
            ),
            child: Stack(
              children: [
                // Collected amount
                if (collected > 0)
                  Container(
                    width: maxAmount > 0 ? (collected / maxAmount) * MediaQuery.of(context).size.width * 0.7 : 0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppTheme.success,
                    ),
                  ),
                // Due amount
                if (due > 0)
                  Positioned(
                    left: maxAmount > 0 ? (collected / maxAmount) * MediaQuery.of(context).size.width * 0.7 : 0,
                    child: Container(
                      width: maxAmount > 0 ? (due / maxAmount) * MediaQuery.of(context).size.width * 0.7 : 0,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: AppTheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalExpected = (_feesSummary!['totalCollected'] as double) + (_feesSummary!['totalDue'] as double);
    final collectionRate = totalExpected > 0 ? ((_feesSummary!['totalCollected'] as double) / totalExpected * 100) : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
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
                  Icons.analytics_rounded,
                  color: AppTheme.textOnPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Statistics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Collection Rate',
                  '${collectionRate.toStringAsFixed(1)}%',
                  Icons.trending_up_rounded,
                  collectionRate >= 80 ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Expected Total',
                  '₹${totalExpected.toInt()}',
                  Icons.account_balance_wallet_rounded,
                  AppTheme.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
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
                  Icons.backup_rounded,
                  color: AppTheme.textOnPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Data Backup',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Secure your data with cloud backup options',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _handleBackupExport,
                  icon: _isExporting 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.cloud_upload_rounded),
                  label: Text(_isExporting ? 'Exporting...' : 'Export Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _handleBackupImport,
                  icon: _isImporting 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.cloud_download_rounded),
                  label: Text(_isImporting ? 'Importing...' : 'Import Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagement() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  Icons.cloud_sync_rounded,
                  color: AppTheme.textOnPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Data Management',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Export Data',
                  'Backup all students and fees',
                  Icons.file_download_rounded,
                  AppTheme.success,
                  _handleExport,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Import Data',
                  'Restore from backup file',
                  Icons.file_upload_rounded,
                  AppTheme.primaryColor,
                  _handleImport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle backup export functionality with progress indication
  Future<void> _handleBackupExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Export data using existing service
      final exportService = DataImportExportService();
      final file = await exportService.exportData();

      setState(() {
        _isExporting = false;
      });

      // Show success SnackBar with file path
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('Export Successful', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'File: ${file.path}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      // Show error SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Export failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// Handle backup import functionality with progress indication
  Future<void> _handleBackupImport() async {
    setState(() {
      _isImporting = true;
    });

    try {
      // Use the import service
      final importService = DataImportService();
      final ImportResult result = await importService.importData(context);

      setState(() {
        _isImporting = false;
      });

      // Show result SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      result.success ? Icons.check_circle : Icons.error,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.success ? 'Import Successful' : 'Import Failed',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (result.importedStudents != null)
                  Text('Students: ${result.importedStudents}', style: const TextStyle(fontSize: 12)),
                if (result.importedFees != null)
                  Text('Fees: ${result.importedFees}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: result.success ? AppTheme.success : AppTheme.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      // Refresh data if import was successful
      if (result.success) {
        _loadOverviewData();
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      
      // Show error SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Import failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// Handle export data functionality
  Future<void> _handleExport() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Exporting data...'),
            ],
          ),
        ),
      );

      // Export data using existing service
      final exportService = DataImportExportService();
      final file = await exportService.exportData();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.success),
              const SizedBox(width: 8),
              const Text('Export Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data has been exported successfully.'),
              const SizedBox(height: 8),
              Text(
                'File saved to: ${file.path}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: AppTheme.error),
              const SizedBox(width: 8),
              const Text('Export Failed'),
            ],
          ),
          content: Text('Failed to export data: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Handle import data functionality
  Future<void> _handleImport() async {
    try {
      // Use the new import service
      final importService = DataImportService();
      final ImportResult result = await importService.importData(context);

      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: result.success ? AppTheme.success : AppTheme.error,
              ),
              const SizedBox(width: 8),
              Text(result.success ? 'Import Successful' : 'Import Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              if (result.importedStudents != null) ...[
                const SizedBox(height: 8),
                Text('Students imported: ${result.importedStudents}'),
              ],
              if (result.importedFees != null) ...[
                const SizedBox(height: 4),
                Text('Fees imported: ${result.importedFees}'),
              ],
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.errors.map((error) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text(
                    '• $error',
                    style: TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                )),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Refresh data if import was successful
                if (result.success) {
                  _loadOverviewData();
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Show error dialog for unexpected errors
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: AppTheme.error),
              const SizedBox(width: 8),
              const Text('Import Error'),
            ],
          ),
          content: Text('An unexpected error occurred: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Build Schools Management section
  Widget _buildSchoolsManagement() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                child: const Icon(
                  Icons.school_rounded,
                  color: AppTheme.textOnPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'School Management',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage school names for student admissions',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageSchoolsScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.settings_rounded,
                  color: AppTheme.textOnPrimary,
                  size: 20,
                ),
                label: const Text(
                  'Manage Schools',
                  style: TextStyle(
                    color: AppTheme.textOnPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

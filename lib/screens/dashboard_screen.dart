import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/student.dart';
import 'add_edit_student_screen.dart';
import 'dart:math';
import 'dart:io';
import 'dart:ui';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mainTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mainTabController.dispose();
    super.dispose();
  }

  List<Student> _recentAdmissions(List<Student> students, {int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return students.where((s) => s.admissionDate.isAfter(cutoff)).toList();
  }

  List<Student> _upcomingBirthdays(List<Student> students, {int days = 30}) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    return students.where((s) {
      final thisYearBirthday = DateTime(now.year, s.dob.month, s.dob.day);
      return thisYearBirthday.isAfter(now) && thisYearBirthday.isBefore(cutoff);
    }).toList();
  }

  double _averageFee(List<Student> students) {
    if (students.isEmpty) return 0.0;
    return students.fold<double>(0, (sum, s) => sum + s.fees) / students.length;
  }

  Map<String, double> _averageFeePerClass(List<Student> students) {
    final classMap = <String, List<Student>>{};
    for (final s in students) {
      classMap.putIfAbsent(s.className, () => []).add(s);
    }
    return classMap.map((k, v) => MapEntry(k, _averageFee(v)));
  }

  void _showStudentFeesSheet(BuildContext context, Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFeesPage(student: student),
      ),
    );
  }

  Widget modernCard({
    required Widget child,
    Color? color,
    Gradient? gradient,
    double? height,
    EdgeInsets? padding,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 500;
    final cardPadding = EdgeInsets.all(isMobile ? 16.0 : 28.0);
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w600, letterSpacing: 0.2);
    final displayStyle = Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: isMobile ? 26 : 38, fontWeight: FontWeight.bold, letterSpacing: 0.5);
    final cardRadius = BorderRadius.circular(isMobile ? 22 : 28);
    final cardShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.07),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.blueAccent.withOpacity(0.06),
        blurRadius: 18,
        offset: const Offset(0, 2),
      ),
    ];
    final cardGradient = LinearGradient(
      colors: [
        Colors.white.withOpacity(0.95),
        Colors.blue.shade50.withOpacity(0.85),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        gradient: gradient ?? cardGradient,
        borderRadius: cardRadius,
        boxShadow: cardShadow,
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1.2),
      ),
      child: Padding(
        padding: padding ?? cardPadding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        bottom: TabBar(
          controller: _mainTabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Fees Management', icon: Icon(Icons.payments)),
            Tab(text: 'Reports', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      floatingActionButton: _mainTabController.index == 0
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
              ),
            )
          : null,
      body: Stack(
        children: [
          Positioned.fill(
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
          TabBarView(
            controller: _mainTabController,
            children: [
              _buildOverviewTab(context),
              _buildFeesTab(context),
              _buildReportsTab(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 500;
    final cardPadding = EdgeInsets.all(isMobile ? 16.0 : 28.0);
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w600, letterSpacing: 0.2);
    final displayStyle = Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: isMobile ? 26 : 38, fontWeight: FontWeight.bold, letterSpacing: 0.5);
    final cardRadius = BorderRadius.circular(isMobile ? 22 : 28);
    final cardShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.07),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.blueAccent.withOpacity(0.06),
        blurRadius: 18,
        offset: const Offset(0, 2),
      ),
    ];
    final cardGradient = LinearGradient(
      colors: [
        Colors.white.withOpacity(0.95),
        Colors.blue.shade50.withOpacity(0.85),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return FutureBuilder<Box<Student>>(
      future: Hive.openBox<Student>('students'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final box = snapshot.data!;
        final students = box.values.toList();
        final totalStudents = students.length;
        final totalFees = students.fold<double>(0, (sum, s) => sum + s.fees);
        final classCounts = <String, int>{};
        for (final s in students) {
          classCounts[s.className] = (classCounts[s.className] ?? 0) + 1;
        }
        final recent = _recentAdmissions(students, days: 7);
        final birthdays = _upcomingBirthdays(students, days: 30);
        final avgFee = _averageFee(students);
        final avgFeePerClass = _averageFeePerClass(students);
        
        // Outstanding calculation
        final now = DateTime.now();
        final currentYear = now.year;
        double totalOutstanding = 0.0;
        for (final s in students) {
          final paidAmountMap = s.paidAmountByYearMonth[currentYear] ?? {};
          for (int m = 1; m <= 12; m++) {
            final paidAmount = paidAmountMap[m] ?? 0.0;
            if (paidAmount < s.fees && m <= now.month) {
              totalOutstanding += (s.fees - paidAmount);
            }
          }
        }

        Widget animatedCounter({required int value, required TextStyle style}) {
          return TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            builder: (context, val, _) => Text('$val', style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        }

        Widget animatedDouble({required double value, required TextStyle style, int decimals = 2}) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            builder: (context, val, _) => Text(val.toStringAsFixed(decimals), style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Outstanding Widget
              modernCard(
                color: Colors.red[50],
                gradient: LinearGradient(
                  colors: [Colors.red[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                height: isMobile ? 100 : 120,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.18),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: isMobile ? 32 : 44),
                    ),
                    SizedBox(width: isMobile ? 14 : 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Total Outstanding Fees', style: titleStyle?.copyWith(color: Colors.red[700])),
                        Text('₹${totalOutstanding.toStringAsFixed(2)}', style: displayStyle?.copyWith(color: Colors.red[700], fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              // Reminders Widget
              modernCard(
                color: Colors.orange[50],
                gradient: LinearGradient(
                  colors: [Colors.orange[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                height: isMobile ? 120 : 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.orange[700], size: isMobile ? 26 : 36),
                        SizedBox(width: isMobile ? 10 : 16),
                        Expanded(
                          child: Text('Students with Due/Overdue Fees', style: titleStyle?.copyWith(color: Colors.orange[700])),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: students.map((s) {
                          final now = DateTime.now();
                          final currentYear = now.year;
                          final paidAmountMap = s.paidAmountByYearMonth[currentYear] ?? {};
                          int due = 0, overdue = 0;
                          for (int m = 1; m <= 12; m++) {
                            final paidAmount = paidAmountMap[m] ?? 0.0;
                            if (paidAmount < s.fees && m < now.month) overdue++;
                            else if (paidAmount < s.fees && m == now.month) due++;
                          }
                          if (due + overdue == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  overdue > 0 ? Icons.warning_amber_rounded : Icons.access_time,
                                  color: overdue > 0 ? Colors.red : Colors.orange,
                                  size: isMobile ? 18 : 22,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    s.name,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('Class ${s.className}', style: TextStyle(fontSize: isMobile ? 11 : 13)),
                                ),
                                const SizedBox(width: 8),
                                if (overdue > 0)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('$overdue Overdue', style: TextStyle(fontSize: isMobile ? 11 : 13, color: Colors.red)),
                                  ),
                                if (due > 0)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('$due Due', style: TextStyle(fontSize: isMobile ? 11 : 13, color: Colors.orange)),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              // Total Students
              modernCard(
                color: Colors.blue[50],
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                height: isMobile ? 100 : 120,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.18),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.people, color: Colors.blue[700], size: isMobile ? 32 : 44),
                    ),
                    SizedBox(width: isMobile ? 14 : 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Total Students', style: titleStyle),
                        animatedCounter(
                          value: totalStudents,
                          style: displayStyle!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Total Batches (Classes)
              modernCard(
                color: Colors.teal[50],
                gradient: LinearGradient(
                  colors: [Colors.teal[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                height: isMobile ? 100 : 120,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.teal[100],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.18),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.collections_bookmark, color: Colors.teal[700], size: isMobile ? 32 : 44),
                    ),
                    SizedBox(width: isMobile ? 14 : 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Total Batches', style: titleStyle),
                        animatedCounter(
                          value: classCounts.length,
                          style: displayStyle!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Recent Admissions
              modernCard(
                color: Colors.green[50],
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                // Removed height to allow content to expand
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fiber_new, color: Colors.green[700], size: isMobile ? 26 : 36),
                        SizedBox(width: isMobile ? 10 : 16),
                        Expanded(
                          child: Text('Recent Admissions (7 days)', style: titleStyle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    animatedCounter(
                      value: recent.length,
                      style: displayStyle!,
                    ),
                    if (recent.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          ...recent.take(5).map((s) => Chip(
                            avatar: s.photoPath != null && s.photoPath!.isNotEmpty
                                ? CircleAvatar(backgroundImage: FileImage(File(s.photoPath!)))
                                : CircleAvatar(child: Text(s.name[0])),
                            label: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          )),
                          if (recent.length > 5)
                            Chip(
                              label: Text('+${recent.length - 5} more'),
                              backgroundColor: Colors.green[100],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Upcoming Birthdays
              modernCard(
                color: Colors.orange[50],
                gradient: LinearGradient(
                  colors: [Colors.orange[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                height: isMobile ? 120 : 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cake, color: Colors.orange[700], size: isMobile ? 26 : 36),
                        SizedBox(width: isMobile ? 10 : 16),
                        Expanded(
                          child: Text('Upcoming Birthdays (30 days)', style: titleStyle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    animatedCounter(
                      value: birthdays.length,
                      style: displayStyle!,
                    ),
                    if (birthdays.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Column(
                        children: birthdays.take(5).map((s) => ListTile(
                          leading: s.photoPath != null && s.photoPath!.isNotEmpty
                              ? CircleAvatar(backgroundImage: FileImage(File(s.photoPath!)))
                              : CircleAvatar(child: Text(s.name[0])),
                          title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('DOB:  [200b${s.dob.toLocal().toString().split(' ')[0]}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Average Fees
              modernCard(
                color: Colors.purple[50],
                gradient: LinearGradient(
                  colors: [Colors.purple[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                // Removed height to allow content to expand
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.purple[700], size: isMobile ? 26 : 36),
                        SizedBox(width: isMobile ? 10 : 16),
                        Expanded(
                          child: Text('Average Fees', style: titleStyle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Overall: ', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: isMobile ? 14 : 16)),
                        animatedDouble(
                          value: avgFee,
                          style: displayStyle!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Per Class:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: isMobile ? 13 : 15)),
                    ...avgFeePerClass.entries.take(5).map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Text('Class ${e.key}: ', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: isMobile ? 13 : 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                              animatedDouble(
                                value: e.value,
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15),
                              ),
                            ],
                          ),
                        )),
                    if (avgFeePerClass.length > 5)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text('+${avgFeePerClass.length - 5} more classes', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeesTab(BuildContext context) {
    return FutureBuilder<Box<Student>>(
      future: Hive.openBox<Student>('students'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final box = snapshot.data!;
        final students = box.values.toList();
        if (students.isEmpty) {
          return const Center(child: Text('No students found.'));
        }
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;
        
        Future<void> exportToCSV() async {
          List<List<dynamic>> rows = [];
          // Header
          rows.add([
            'Name', 'Class', 'Year', 'Month', 'Status', 'Paid Amount', 'Total Due', 'Outstanding'
          ]);
          for (final s in students) {
            for (int year in s.paidAmountByYearMonth.keys) {
              final paidAmountMap = s.paidAmountByYearMonth[year] ?? {};
              for (int m = 1; m <= 12; m++) {
                final paidAmount = paidAmountMap[m] ?? 0.0;
                final totalDue = s.fees;
                String status;
                if (paidAmount >= totalDue) status = 'Paid';
                else if (paidAmount > 0) status = 'Partial';
                else status = 'Unpaid';
                final outstanding = (paidAmount < totalDue) ? (totalDue - paidAmount) : 0.0;
                rows.add([
                  s.name,
                  s.className,
                  year,
                  m,
                  status,
                  paidAmount,
                  totalDue,
                  outstanding,
                ]);
              }
            }
          }
          String csvData = const ListToCsvConverter().convert(rows);
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/fees_export_${DateTime.now().millisecondsSinceEpoch}.csv');
          await file.writeAsString(csvData);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Exported to ${file.path}')),
            );
          }
        }

        // Filter/search bar state
        final now = DateTime.now();
        final currentYear = now.year;
        final filterOptions = ['All', 'Paid', 'Due', 'Overdue', 'Partial'];
        String selectedFilter = 'All';
        String searchQuery = '';
        
        return StatefulBuilder(
          builder: (context, setFilterState) {
            List<Student> filteredStudents = students.where((s) {
              // Determine payment status for the current year
              final paidAmountByYearMonth = s.paidAmountByYearMonth;
              final admissionYear = s.admissionDate.year;
              final admissionMonth = s.admissionDate.month;
              List<MapEntry<int, int>> monthsToCheck = [];
              for (int year = admissionYear; year <= currentYear; year++) {
                int startMonth = 1;
                int endMonth = 12;
                if (year == admissionYear && year == currentYear) {
                  startMonth = admissionMonth;
                  endMonth = now.month;
                } else if (year == admissionYear) {
                  startMonth = admissionMonth;
                  endMonth = 12;
                } else if (year == currentYear) {
                  startMonth = 1;
                  endMonth = now.month;
                }
                for (int m = startMonth; m <= endMonth; m++) {
                  monthsToCheck.add(MapEntry(year, m));
                }
              }
              int paid = 0, partial = 0, due = 0, overdue = 0;
              for (final ym in monthsToCheck) {
                final paidAmount = paidAmountByYearMonth[ym.key]?[ym.value] ?? 0.0;
                final fee = s.customFeeByYearMonth[ym.key]?[ym.value] ?? s.fees;
                if (paidAmount >= fee) paid++;
                else if (paidAmount > 0 && paidAmount < fee) partial++;
                else if (ym.key < currentYear || ym.value < now.month) overdue++;
                else if (ym.key == currentYear && ym.value == now.month) due++;
              }
              final monthsToCount = monthsToCheck.length;
              bool filterMatch;
              switch (selectedFilter) {
                case 'Paid': filterMatch = paid == monthsToCount; break;
                case 'Partial': filterMatch = partial > 0 && paid < monthsToCount; break;
                case 'Due': filterMatch = due > 0 && paid < monthsToCount; break;
                case 'Overdue': filterMatch = overdue > 0 && paid < monthsToCount; break;
                default: filterMatch = true;
              }
              final query = searchQuery.trim().toLowerCase();
              final searchMatch = query.isEmpty || s.name.toLowerCase().contains(query) || s.className.toLowerCase().contains(query);
              return filterMatch && searchMatch;
            }).toList();

            return Column(
              children: [
                if (isMobile) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name or class',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      ),
                      onChanged: (val) => setFilterState(() => searchQuery = val),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedFilter,
                            items: filterOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                            onChanged: (val) => setFilterState(() => selectedFilter = val!),
                            decoration: InputDecoration(
                              labelText: 'Filter',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Export'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          onPressed: exportToCSV,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Export CSV'),
                          onPressed: exportToCSV,
                        ),
                        const Spacer(),
                        const Text('Filter:'),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: selectedFilter,
                          items: filterOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                          onChanged: (val) => setFilterState(() => selectedFilter = val!),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isWide = width > 900;
                      final isMobile = width < 600;
                      final crossAxisCount = isWide ? 3 : (width > 600 ? 2 : 1);
                      return GridView.builder(
                        padding: EdgeInsets.all(isMobile ? 8 : 20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : crossAxisCount,
                          mainAxisSpacing: isMobile ? 4 : 12,
                          crossAxisSpacing: isMobile ? 0 : 12,
                          childAspectRatio: isMobile ? 2.5 : (isWide ? 2.2 : 1.7),
                        ),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final s = filteredStudents[index];
                          // Payment status calculation
                          final now = DateTime.now();
                          final currentYear = now.year;
                          final paidAmountByYearMonth = s.paidAmountByYearMonth;
                          final admissionYear = s.admissionDate.year;
                          final admissionMonth = s.admissionDate.month;
                          List<MapEntry<int, int>> monthsToCheck = [];
                          for (int year = admissionYear; year <= currentYear; year++) {
                            int startMonth = 1;
                            int endMonth = 12;
                            if (year == admissionYear && year == currentYear) {
                              startMonth = admissionMonth;
                              endMonth = now.month;
                            } else if (year == admissionYear) {
                              startMonth = admissionMonth;
                              endMonth = 12;
                            } else if (year == currentYear) {
                              startMonth = 1;
                              endMonth = now.month;
                            }
                            for (int m = startMonth; m <= endMonth; m++) {
                              monthsToCheck.add(MapEntry(year, m));
                            }
                          }
                          int paid = 0, partial = 0, due = 0, overdue = 0;
                          for (final ym in monthsToCheck) {
                            final paidAmount = paidAmountByYearMonth[ym.key]?[ym.value] ?? 0.0;
                            final fee = s.customFeeByYearMonth[ym.key]?[ym.value] ?? s.fees;
                            if (paidAmount >= fee) paid++;
                            else if (paidAmount > 0 && paidAmount < fee) partial++;
                            else if (ym.key < currentYear || ym.value < now.month) overdue++;
                            else if (ym.key == currentYear && ym.value == now.month) due++;
                          }
                          final monthsToCount = monthsToCheck.length;
                          String status;
                          Color badgeColor;
                          IconData badgeIcon;
                          if (paid == monthsToCount) {
                            status = 'Paid';
                            badgeColor = Colors.green;
                            badgeIcon = Icons.check_circle;
                          } else if (overdue > 0) {
                            status = 'Overdue';
                            badgeColor = Colors.redAccent;
                            badgeIcon = Icons.warning_amber_rounded;
                          } else if (due > 0) {
                            status = 'Due';
                            badgeColor = Colors.orange;
                            badgeIcon = Icons.access_time;
                          } else if (partial > 0) {
                            status = 'Partial';
                            badgeColor = Colors.purple;
                            badgeIcon = Icons.timelapse;
                          } else {
                            status = 'Upcoming';
                            badgeColor = Colors.blueAccent;
                            badgeIcon = Icons.schedule;
                          }
                          return GestureDetector(
                            onTap: () => _showStudentFeesSheet(context, s),
                            child: modernCard(
                              color: Colors.blue[50],
                              gradient: LinearGradient(
                                colors: [Colors.blue[50]!, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              height: isMobile ? 120 : 140,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: badgeColor.withOpacity(0.18),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: s.photoPath != null && s.photoPath!.isNotEmpty
                                        ? CircleAvatar(
                                            radius: isMobile ? 24 : 30,
                                            backgroundImage: FileImage(File(s.photoPath!)),
                                          )
                                        : CircleAvatar(
                                            radius: isMobile ? 24 : 30,
                                            backgroundColor: badgeColor.withOpacity(0.15),
                                            child: Text(
                                              s.name.isNotEmpty ? s.name[0] : '?',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: badgeColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isMobile ? 20 : 26,
                                              ),
                                            ),
                                          ),
                                  ),
                                  SizedBox(width: isMobile ? 18 : 28),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              s.name,
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isMobile ? 19 : 24,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withOpacity(0.13),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.school, color: badgeColor, size: isMobile ? 15 : 18),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    s.className,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: badgeColor,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: isMobile ? 15 : 18,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.currency_rupee, color: badgeColor, size: isMobile ? 17 : 20),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Fees: ₹${s.fees.toStringAsFixed(2)}',
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: badgeColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: isMobile ? 16 : 20,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const Spacer(),
                                            Tooltip(
                                              message: status,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: badgeColor.withOpacity(0.18),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(badgeIcon, color: badgeColor, size: isMobile ? 15 : 18),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      status,
                                                      style: TextStyle(
                                                        color: badgeColor,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: isMobile ? 15 : 18,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReportsTab(BuildContext context) {
    return FutureBuilder<Box<Student>>(
      future: Hive.openBox<Student>('students'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final box = snapshot.data!;
        final students = box.values.toList();
        final now = DateTime.now();
        final currentYear = now.year;
        // Monthly totals
        List<double> monthlyCollected = List.filled(12, 0.0);
        List<double> monthlyOutstanding = List.filled(12, 0.0);
        for (final s in students) {
          final paidAmountMap = s.paidAmountByYearMonth[currentYear] ?? {};
          for (int m = 1; m <= 12; m++) {
            final paidAmount = paidAmountMap[m] ?? 0.0;
            monthlyCollected[m-1] += paidAmount;
            if (paidAmount < s.fees && m <= now.month) {
              monthlyOutstanding[m-1] += (s.fees - paidAmount);
            }
          }
        }
        // Per class breakdown
        final classMap = <String, double>{};
        for (final s in students) {
          classMap[s.className] = (classMap[s.className] ?? 0.0) + ((s.paidAmountByYearMonth[currentYear]?.values ?? []).where((v) => v != null).map((v) => v! as double)).fold<num>(0.0, (num a, num b) => a + b) as double;
        }
        // Per student breakdown
        final studentMap = <String, double>{};
        for (final s in students) {
          studentMap[s.name] = (s.paidAmountByYearMonth[currentYear]?.values ?? []).where((v) => v != null).map((v) => v! as double).fold(0.0, (double a, double b) => a + b);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Monthly Collected (₹)', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(12, (i) => Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Container(
                            height: (monthlyCollected[i] / 10).clamp(0, 160),
                            color: Colors.green,
                            width: 16,
                          ),
                        ),
                        Text(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][i], style: const TextStyle(fontSize: 12)),
                        Text('₹${monthlyCollected[i].toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 24),
              Text('Monthly Outstanding (₹)', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(12, (i) => Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Container(
                            height: (monthlyOutstanding[i] / 10).clamp(0, 160),
                            color: Colors.red,
                            width: 16,
                          ),
                        ),
                        Text(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][i], style: const TextStyle(fontSize: 12)),
                        Text('₹${monthlyOutstanding[i].toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 24),
              Text('Collected per Class (₹)', style: Theme.of(context).textTheme.titleLarge),
              ...classMap.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Text('Class ${e.key}: ', style: Theme.of(context).textTheme.bodyLarge),
                    Text('₹${e.value.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              Text('Collected per Student (₹)', style: Theme.of(context).textTheme.titleLarge),
              ...studentMap.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Text('${e.key}: ', style: Theme.of(context).textTheme.bodyLarge),
                    Text('₹${e.value.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

class StudentFeesPage extends StatefulWidget {
  final Student student;
  const StudentFeesPage({Key? key, required this.student}) : super(key: key);

  @override
  State<StudentFeesPage> createState() => _StudentFeesPageState();
}

class _StudentFeesPageState extends State<StudentFeesPage> {
  late int selectedYear;
  late int minYear;
  late int maxYear;
  late List<String> months;
  late DateTime now;
  Set<int> selectedMonths = {};

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    minYear = widget.student.admissionDate.year;
    maxYear = now.year + 10;
    if (widget.student.paidMonthsByYear.isNotEmpty && widget.student.paidMonthsByYear.keys.contains(now.year)) {
      selectedYear = now.year;
    } else if (widget.student.paidMonthsByYear.isNotEmpty) {
      selectedYear = widget.student.paidMonthsByYear.keys.first;
    } else {
      selectedYear = now.year;
    }
  }

  void setYear(int year) {
    setState(() {
      selectedYear = year;
      selectedMonths.clear();
    });
  }

  void paySelectedMonths() async {
    if (selectedMonths.isEmpty) return;
    final student = widget.student;
    final total = selectedMonths.fold<double>(0.0, (sum, m) {
      final paid = student.paidAmountByYearMonth[selectedYear]?[m] ?? 0.0;
      final due = (student.customFeeByYearMonth[selectedYear]?[m] ?? student.fees) - paid;
      return sum + (due > 0 ? due : 0);
    });
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Bulk Pay Fees'),
        content: Text('Pay ₹${total.toStringAsFixed(2)} for ${selectedMonths.length} months?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pay')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        for (final m in selectedMonths) {
          final fee = student.customFeeByYearMonth[selectedYear]?[m] ?? student.fees;
          student.paidAmountByYearMonth.putIfAbsent(selectedYear, () => {});
          student.paidAmountByYearMonth[selectedYear]![m] = fee;
          student.paidMonthsByYear.putIfAbsent(selectedYear, () => <int>{});
          student.paidMonthsByYear[selectedYear]!.add(m);
        }
        student.save();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paid ₹${total.toStringAsFixed(2)} for ${selectedMonths.length} months')),
      );
      selectedMonths.clear();
    }
  }

  void payMonth(int monthIndex) async {
    final student = widget.student;
    final monthName = months[monthIndex];
    final fee = student.customFeeByYearMonth[selectedYear]?[monthIndex + 1] ?? student.fees;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Pay Fees'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pay fees for $monthName $selectedYear?'),
            const SizedBox(height: 12),
            Text('Amount: ₹${fee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        widget.student.paidAmountByYearMonth.putIfAbsent(selectedYear, () => {});
        widget.student.paidAmountByYearMonth[selectedYear]![monthIndex + 1] = fee;
        widget.student.paidMonthsByYear.putIfAbsent(selectedYear, () => <int>{});
        widget.student.paidMonthsByYear[selectedYear]!.add(monthIndex + 1);
        widget.student.save();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('Fees paid successfully!'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    // Calculate summary
    final paidAmountMap = student.paidAmountByYearMonth[selectedYear] ?? {};
    double totalPaid = 0.0, totalDue = 0.0, totalOutstanding = 0.0;
    for (int m = 1; m <= 12; m++) {
      final paid = paidAmountMap[m] ?? 0.0;
      final fee = student.customFeeByYearMonth[selectedYear]?[m] ?? student.fees;
      totalPaid += paid;
      totalDue += fee;
      if (paid < fee && m <= now.month) {
        totalOutstanding += (fee - paid);
      }
    }
    Widget yearSelector() => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_left, size: isMobile ? 28 : 22),
          onPressed: selectedYear > minYear ? () => setYear(selectedYear - 1) : null,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 8, vertical: isMobile ? 8 : 0),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$selectedYear', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: isMobile ? 22 : null)),
        ),
        IconButton(
          icon: Icon(Icons.arrow_right, size: isMobile ? 28 : 22),
          onPressed: selectedYear < maxYear ? () => setYear(selectedYear + 1) : null,
        ),
      ],
    );
    Widget paySelectedButton() => ElevatedButton.icon(
      icon: const Icon(Icons.payments),
      label: const Text('Pay Selected'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 14, vertical: isMobile ? 16 : 8),
        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 18 : 14),
      ),
      onPressed: selectedMonths.isNotEmpty ? paySelectedMonths : null,
    );
    return Stack(
      children: [
        // Glassmorphism background
        Positioned.fill(
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
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.white.withOpacity(0.12)),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white.withOpacity(0.85),
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: student.photoPath != null && student.photoPath!.isNotEmpty
                      ? FileImage(File(student.photoPath!))
                      : null,
                  child: (student.photoPath == null || student.photoPath!.isEmpty)
                      ? Icon(Icons.person, size: 22, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        student.className,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Remove year selector and pay selected from AppBar on mobile
            actions: isMobile ? null : [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: selectedYear > minYear ? () => setYear(selectedYear - 1) : null,
              ),
              Center(child: Text('$selectedYear', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: selectedYear < maxYear ? () => setYear(selectedYear + 1) : null,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.payments),
                label: const Text('Pay Selected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: selectedMonths.isNotEmpty ? paySelectedMonths : null,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              if (isMobile) ...[
                const SizedBox(height: 10),
                yearSelector(),
                const SizedBox(height: 10),
                paySelectedButton(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.money_off, color: Colors.red[700], size: 28),
                          Text('Total Due', style: Theme.of(context).textTheme.bodyMedium),
                          Text('₹${totalDue.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                          Text('Paid', style: Theme.of(context).textTheme.bodyMedium),
                          Text('₹${totalPaid.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
                          Text('Outstanding', style: Theme.of(context).textTheme.bodyMedium),
                          Text('₹${totalOutstanding.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Card(
                    color: Colors.white.withOpacity(0.85),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text('Total Due', style: Theme.of(context).textTheme.bodyMedium),
                              Text('₹${totalDue.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red[700], fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('Paid', style: Theme.of(context).textTheme.bodyMedium),
                              Text('₹${totalPaid.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('Outstanding', style: Theme.of(context).textTheme.bodyMedium),
                              Text('₹${totalOutstanding.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (width > 900 ? 5 : width > 600 ? 4 : 2),
                      mainAxisSpacing: isMobile ? 14 : 18,
                      crossAxisSpacing: isMobile ? 0 : 18,
                      childAspectRatio: isMobile ? 3.5 : 1.1,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, i) {
                      final monthIndex = i;
                      final monthName = months[monthIndex];
                      final paidAmount = student.paidAmountByYearMonth[selectedYear]?[monthIndex + 1] ?? 0.0;
                      final customFee = student.customFeeByYearMonth[selectedYear]?[monthIndex + 1];
                      final totalDue = customFee ?? student.fees;
                      final isPaid = paidAmount >= totalDue;
                      final isPartial = paidAmount > 0 && paidAmount < totalDue;
                      final isCurrentYear = selectedYear == now.year;
                      final isPastYear = selectedYear < now.year;
                      final isFutureYear = selectedYear > now.year;
                      final isUpcoming = isFutureYear || (isCurrentYear && (monthIndex + 1) > now.month);
                      final isDueSoon = !isPaid && !isPartial && isCurrentYear && (monthIndex + 1) == now.month;
                      final isOverdue = !isPaid && !isPartial && ((isCurrentYear && (monthIndex + 1) < now.month) || isPastYear);
                      Color cardColor;
                      IconData icon;
                      String status;
                      Color iconColor;
                      if (isPaid) {
                        cardColor = Colors.green[50]!;
                        icon = Icons.check_circle;
                        status = 'Paid';
                        iconColor = Colors.green;
                      } else if (isPartial) {
                        cardColor = Colors.purple[50]!;
                        icon = Icons.timelapse;
                        status = 'Partial';
                        iconColor = Colors.purple;
                      } else if (isDueSoon) {
                        cardColor = Colors.orange[50]!;
                        icon = Icons.access_time;
                        status = 'Due Soon';
                        iconColor = Colors.orange;
                      } else if (isOverdue) {
                        cardColor = Colors.red[50]!;
                        icon = Icons.warning_amber_rounded;
                        status = 'Overdue';
                        iconColor = Colors.redAccent;
                      } else {
                        cardColor = Colors.blue[50]!;
                        icon = Icons.schedule;
                        status = 'Upcoming';
                        iconColor = Colors.blueAccent;
                      }
                      final isSelected = selectedMonths.contains(monthIndex + 1);
                      return GestureDetector(
                        onTap: isPaid ? null : () {
                          setState(() {
                            if (isSelected) {
                              selectedMonths.remove(monthIndex + 1);
                            } else {
                              selectedMonths.add(monthIndex + 1);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.teal[100] : cardColor,
                            borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
                            boxShadow: [
                              BoxShadow(
                                color: iconColor.withOpacity(0.10),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: isSelected ? Colors.teal : iconColor.withOpacity(0.18),
                              width: isSelected ? 2.2 : 1.2,
                            ),
                            backgroundBlendMode: BlendMode.overlay,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 14 : 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(icon, color: iconColor, size: isMobile ? 28 : 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              monthName,
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (isSelected && !isPaid)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 6.0),
                                                child: Icon(Icons.check_circle, color: Colors.teal, size: 18),
                                              ),
                                          ],
                                        ),
                                        if (customFee != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 1.0),
                                            child: Text('₹${customFee.toStringAsFixed(0)}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: iconColor.withOpacity(0.13),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: iconColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: isMobile ? 12 : 10,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isPartial)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 1.0),
                                            child: Text(
                                              '₹${paidAmount.toStringAsFixed(0)}/${totalDue.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: Colors.purple,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isMobile ? 12 : 10,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
        ),
      ],
    );
  }
}
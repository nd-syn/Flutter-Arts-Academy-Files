import 'package:arts_academy/models/fee_model.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/services/database_helper.dart';

class FeeService {
  static final FeeService instance = FeeService._privateConstructor();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  
  FeeService._privateConstructor();

  /// Get current month (1-12)
  int get currentMonth => DateTime.now().month;
  
  /// Get current year
  int get currentYear => DateTime.now().year;

  /// Get month name from month number
  String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Get all months after current month as upcoming
  List<int> getUpcomingMonths() {
    List<int> upcoming = [];
    for (int month = currentMonth + 1; month <= 12; month++) {
      upcoming.add(month);
    }
    return upcoming;
  }

  /// Get all months from January to current month as due
  List<int> getDueMonths() {
    List<int> due = [];
    for (int month = 1; month <= currentMonth; month++) {
      due.add(month);
    }
    return due;
  }

  /// Calculate fee status for a specific student
  Future<Map<String, dynamic>> calculateStudentFeeStatus(Student student) async {
    List<Fee> studentFees = await _databaseHelper.getFeesForStudent(student.id!);
    
    // Filter fees for current year
    List<Fee> currentYearFees = studentFees
        .where((fee) => fee.paymentYear == currentYear)
        .toList();

    // Group fees by month
    Map<int, Fee> paidMonths = {};
    for (var fee in currentYearFees) {
      if (fee.paymentStatus.toLowerCase() == 'paid') {
        paidMonths[fee.paymentMonth] = fee;
      }
    }

    // Calculate upcoming months (current to December)
    List<int> upcomingMonths = getUpcomingMonths();
    List<int> dueMonths = getDueMonths();

    // Count paid, due, and upcoming months
    int paidUpcomingCount = 0;
    int paidDueCount = 0;
    
    for (int month in upcomingMonths) {
      if (paidMonths.containsKey(month)) {
        paidUpcomingCount++;
      }
    }
    
    for (int month in dueMonths) {
      if (paidMonths.containsKey(month)) {
        paidDueCount++;
      }
    }

    // Calculate totals
    double totalUpcomingAmount = upcomingMonths.length * student.fees;
    double totalDueAmount = dueMonths.length * student.fees;
    double paidUpcomingAmount = paidUpcomingCount * student.fees;
    double paidDueAmount = paidDueCount * student.fees;
    double pendingUpcomingAmount = totalUpcomingAmount - paidUpcomingAmount;
    double pendingDueAmount = totalDueAmount - paidDueAmount;

    // Determine overall status
    String overallStatus;
    if (pendingDueAmount > 0) {
      overallStatus = 'Due'; // Has overdue payments
    } else if (pendingUpcomingAmount > 0) {
      overallStatus = 'Upcoming'; // Has upcoming payments
    } else {
      overallStatus = 'Paid'; // All fees paid
    }

    return {
      'student': student,
      'overallStatus': overallStatus,
      'currentMonth': currentMonth,
      'currentYear': currentYear,
      
      // Upcoming months data
      'upcomingMonths': upcomingMonths,
      'totalUpcomingMonths': upcomingMonths.length,
      'paidUpcomingMonths': paidUpcomingCount,
      'pendingUpcomingMonths': upcomingMonths.length - paidUpcomingCount,
      'totalUpcomingAmount': totalUpcomingAmount,
      'paidUpcomingAmount': paidUpcomingAmount,
      'pendingUpcomingAmount': pendingUpcomingAmount,
      
      // Due months data
      'dueMonths': dueMonths,
      'totalDueMonths': dueMonths.length,
      'paidDueMonths': paidDueCount,
      'pendingDueMonths': dueMonths.length - paidDueCount,
      'totalDueAmount': totalDueAmount,
      'paidDueAmount': paidDueAmount,
      'pendingDueAmount': pendingDueAmount,
      
      // Total summary
      'totalMonthsInYear': 12,
      'totalPaidMonths': paidUpcomingCount + paidDueCount,
      'totalPendingMonths': (upcomingMonths.length - paidUpcomingCount) + (dueMonths.length - paidDueCount),
      'totalPaidAmount': paidUpcomingAmount + paidDueAmount,
      'totalPendingAmount': pendingUpcomingAmount + pendingDueAmount,
      
      // Detailed month status
      'monthlyDetails': _getMonthlyDetails(paidMonths, student.fees),
    };
  }

  /// Get detailed status for each month
  Map<int, Map<String, dynamic>> _getMonthlyDetails(Map<int, Fee> paidMonths, double monthlyFee) {
    Map<int, Map<String, dynamic>> monthlyDetails = {};
    
    for (int month = 1; month <= 12; month++) {
      String status;
      bool isPaid = paidMonths.containsKey(month);
      
      if (month <= currentMonth) {
        // Past months and current month - if not paid, they are due
        status = isPaid ? 'Paid' : 'Due';
      } else {
        // Future months
        status = isPaid ? 'Paid' : 'Upcoming';
      }
      
      monthlyDetails[month] = {
        'monthName': getMonthName(month),
        'monthNumber': month,
        'status': status,
        'amount': monthlyFee,
        'paid': isPaid,
        'fee': paidMonths[month], // null if not paid
        'isPastDue': month < currentMonth && !isPaid,
        'isCurrent': month == currentMonth,
        'isCurrentDue': month == currentMonth && !isPaid,
        'isUpcoming': month > currentMonth,
      };
    }
    
    return monthlyDetails;
  }

  /// Get all students with their fee status
  Future<List<Map<String, dynamic>>> getAllStudentsWithFeeStatus() async {
    try {
      List<Student> students = await _databaseHelper.getAllStudents();
      List<Map<String, dynamic>> studentsWithStatus = [];
      
      for (Student student in students) {
        Map<String, dynamic> feeStatus = await calculateStudentFeeStatus(student);
        studentsWithStatus.add(feeStatus);
      }
      
      // Sort by priority: Due first, then Upcoming, then Paid
      studentsWithStatus.sort((a, b) {
        int statusPriority(String status) {
          switch (status) {
            case 'Due': return 0;
            case 'Upcoming': return 1;
            case 'Paid': return 2;
            default: return 3;
          }
        }
        
        int statusCompare = statusPriority(a['overallStatus']).compareTo(statusPriority(b['overallStatus']));
        if (statusCompare != 0) return statusCompare;
        
        // If same status, sort by student name
        return (a['student'] as Student).name.compareTo((b['student'] as Student).name);
      });
      
      return studentsWithStatus;
    } catch (e) {
      throw Exception('Failed to load students with fee status: $e');
    }
  }

  /// Get summary statistics for all students
  Future<Map<String, dynamic>> getFeesSummary() async {
    try {
      List<Map<String, dynamic>> studentsWithStatus = await getAllStudentsWithFeeStatus();
      
      double totalCollected = 0;
      double totalDue = 0;
      double totalUpcoming = 0;
      int studentsWithDues = 0;
      int studentsFullyPaid = 0;
      int studentsWithUpcoming = 0;
      
      for (var studentData in studentsWithStatus) {
        totalCollected += studentData['totalPaidAmount'];
        totalDue += studentData['pendingDueAmount'];
        totalUpcoming += studentData['pendingUpcomingAmount'];
        
        String status = studentData['overallStatus'];
        switch (status) {
          case 'Due':
            studentsWithDues++;
            break;
          case 'Upcoming':
            studentsWithUpcoming++;
            break;
          case 'Paid':
            studentsFullyPaid++;
            break;
        }
      }
      
      return {
        'totalStudents': studentsWithStatus.length,
        'totalCollected': totalCollected,
        'totalDue': totalDue,
        'totalUpcoming': totalUpcoming,
        'totalExpected': totalCollected + totalDue + totalUpcoming,
        'studentsWithDues': studentsWithDues,
        'studentsWithUpcoming': studentsWithUpcoming,
        'studentsFullyPaid': studentsFullyPaid,
        'currentMonth': getMonthName(currentMonth),
        'currentYear': currentYear,
      };
    } catch (e) {
      throw Exception('Failed to generate fees summary: $e');
    }
  }

  /// Check if a specific student has due payments
  Future<bool> hasOverduePayments(int studentId) async {
    Student? student = await _databaseHelper.getStudent(studentId);
    if (student == null) return false;
    
    Map<String, dynamic> feeStatus = await calculateStudentFeeStatus(student);
    return feeStatus['pendingDueAmount'] > 0;
  }

  /// Get the next due date for a student
  Future<DateTime?> getNextDueDate(int studentId) async {
    Student? student = await _databaseHelper.getStudent(studentId);
    if (student == null) return null;
    
    Map<String, dynamic> feeStatus = await calculateStudentFeeStatus(student);
    Map<int, Map<String, dynamic>> monthlyDetails = feeStatus['monthlyDetails'];
    
    // Find the first unpaid month starting from current month backwards for dues
    // or current month forwards for upcoming
    for (int month = 1; month <= currentMonth; month++) {
      if (!monthlyDetails[month]!['paid']) {
        return DateTime(currentYear, month, 1);
      }
    }
    
    // If no due payments, return current month if not paid
    if (!monthlyDetails[currentMonth]!['paid']) {
      return DateTime(currentYear, currentMonth, 1);
    }
    
    return null;
  }
}

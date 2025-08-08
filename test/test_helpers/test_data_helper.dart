import 'dart:math';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/models/fee_model.dart';

class TestDataHelper {
  static final Random _random = Random();

  static List<String> sampleNames = [
    'John Smith', 'Emma Johnson', 'Michael Brown', 'Sophia Davis', 'William Miller',
    'Olivia Wilson', 'James Moore', 'Ava Taylor', 'Benjamin Anderson', 'Isabella Thomas',
    'Lucas Jackson', 'Mia White', 'Henry Harris', 'Charlotte Martin', 'Alexander Garcia',
    'Amelia Rodriguez', 'Daniel Lewis', 'Harper Lee', 'Matthew Walker', 'Evelyn Hall'
  ];

  static List<String> sampleClasses = ['9', '10', '11', '12'];
  
  static List<String> sampleSchools = [
    'Springfield High School', 'Riverside Academy', 'Oak Valley School',
    'Maple Grove High', 'Cedar Point Academy', 'Pine Hill School'
  ];

  static List<String> sampleSubjects = [
    'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English', 'History',
    'Geography', 'Computer Science', 'Economics', 'Psychology'
  ];

  static List<String> sampleAddresses = [
    '123 Main Street, Springfield',
    '456 Oak Avenue, Riverside',
    '789 Pine Road, Oakville',
    '321 Elm Street, Cedar Falls',
    '654 Maple Lane, Willowbrook',
    '987 Birch Drive, Fairview'
  ];

  /// Generates a list of test students with realistic data
  static List<Student> generateTestStudents(int count) {
    final students = <Student>[];
    
    for (int i = 0; i < count; i++) {
      final name = sampleNames[_random.nextInt(sampleNames.length)];
      final studentClass = sampleClasses[_random.nextInt(sampleClasses.length)];
      final school = sampleSchools[_random.nextInt(sampleSchools.length)];
      final address = sampleAddresses[_random.nextInt(sampleAddresses.length)];
      
      // Generate subject combinations
      final selectedSubjects = <String>[];
      final numSubjects = 3 + _random.nextInt(4); // 3-6 subjects
      while (selectedSubjects.length < numSubjects) {
        final subject = sampleSubjects[_random.nextInt(sampleSubjects.length)];
        if (!selectedSubjects.contains(subject)) {
          selectedSubjects.add(subject);
        }
      }
      
      final student = Student(
        name: name,
        studentClass: studentClass,
        school: school,
        version: 1,
        guardianName: _generateGuardianName(name),
        guardianPhone: _generatePhoneNumber(),
        studentPhone: _generatePhoneNumber(),
        subjects: selectedSubjects.join(', '),
        fees: _generateMonthlyFees(),
        address: address,
        admissionDate: _generateAdmissionDate(),
        dob: _generateDateOfBirth(int.parse(studentClass)),
      );
      
      students.add(student);
    }
    
    return students;
  }

  /// Generates test fees for the given students
  static List<Fee> generateTestFees(List<Student> students, int totalFees) {
    final fees = <Fee>[];
    final currentYear = DateTime.now().year;
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    final paymentStatuses = ['Paid', 'Pending', 'Overdue'];
    
    for (int i = 0; i < totalFees; i++) {
      final student = students[_random.nextInt(students.length)];
      final month = months[_random.nextInt(months.length)];
      final year = currentYear - _random.nextInt(2); // Current or previous year
      final status = paymentStatuses[_random.nextInt(paymentStatuses.length)];
      
      final fee = Fee(
        studentId: student.id ?? (i + 1), // Use index + 1 if student.id is null
        amount: student.fees,
        paymentDate: _generatePaymentDate(status),
        paymentMonth: month,
        paymentYear: year,
        paymentStatus: status,
      );
      
      fees.add(fee);
    }
    
    return fees;
  }

  static String _generateGuardianName(String studentName) {
    final firstName = studentName.split(' ')[0];
    final guardianPrefixes = ['Mr. ', 'Mrs. ', 'Ms. ', 'Dr. '];
    final guardianSuffixes = [' Sr.', ' Jr.', ''];
    
    final prefix = guardianPrefixes[_random.nextInt(guardianPrefixes.length)];
    final suffix = guardianSuffixes[_random.nextInt(guardianSuffixes.length)];
    
    // Generate a different first name for guardian
    final guardianFirstNames = ['Robert', 'Linda', 'David', 'Susan', 'Richard', 
                               'Karen', 'Joseph', 'Nancy', 'Thomas', 'Betty'];
    final guardianFirstName = guardianFirstNames[_random.nextInt(guardianFirstNames.length)];
    
    return '$prefix$guardianFirstName ${studentName.split(' ').last}$suffix';
  }

  static String _generatePhoneNumber() {
    // Generate a realistic phone number format: +1 (xxx) xxx-xxxx
    final areaCode = 200 + _random.nextInt(800);
    final exchange = 200 + _random.nextInt(800);
    final number = 1000 + _random.nextInt(9000);
    
    return '+1 ($areaCode) $exchange-$number';
  }

  static int _generateMonthlyFees() {
    // Generate monthly fees between $50 and $500
    final baseFee = 50 + _random.nextInt(451);
    return baseFee;
  }

  static DateTime _generateAdmissionDate() {
    // Generate admission date within the last 2 years
    final now = DateTime.now();
    final daysAgo = _random.nextInt(730); // Up to 2 years ago
    return now.subtract(Duration(days: daysAgo));
  }

  static DateTime _generateDateOfBirth(int grade) {
    // Estimate age based on grade (grade 9 = ~14 years old, grade 12 = ~17 years old)
    final estimatedAge = 14 + (grade - 9);
    final now = DateTime.now();
    
    // Add some randomness (±1 year)
    final actualAge = estimatedAge + _random.nextInt(3) - 1;
    final daysVariation = _random.nextInt(365); // Random day within the year
    
    return DateTime(
      now.year - actualAge,
      1 + _random.nextInt(12), // Random month
      1 + _random.nextInt(28), // Random day (safe for all months)
    );
  }

  static DateTime _generatePaymentDate(String status) {
    final now = DateTime.now();
    
    switch (status) {
      case 'Paid':
        // Payment date within the last 30 days
        final daysAgo = _random.nextInt(30);
        return now.subtract(Duration(days: daysAgo));
      case 'Pending':
        // Future payment date (within next 15 days)
        final daysAhead = _random.nextInt(15);
        return now.add(Duration(days: daysAhead));
      case 'Overdue':
        // Payment date in the past (1-60 days ago)
        final daysAgo = 1 + _random.nextInt(60);
        return now.subtract(Duration(days: daysAgo));
      default:
        return now;
    }
  }

  /// Creates a student with specific test data for edge cases
  static Student createStudentWithSpecificData({
    String? name,
    String? studentClass,
    String? school,
    String? guardianName,
    String? guardianPhone,
    String? studentPhone,
    String? subjects,
    int? fees,
    String? address,
    DateTime? admissionDate,
    DateTime? dob,
  }) {
    return Student(
      name: name ?? 'Test Student',
      studentClass: studentClass ?? '10',
      school: school ?? 'Test School',
      version: 1,
      guardianName: guardianName ?? 'Test Guardian',
      guardianPhone: guardianPhone ?? '+1 (555) 123-4567',
      studentPhone: studentPhone ?? '+1 (555) 987-6543',
      subjects: subjects ?? 'Math, Science',
      fees: fees ?? 100,
      address: address ?? '123 Test Street',
      admissionDate: admissionDate ?? DateTime.now(),
      dob: dob ?? DateTime.now().subtract(const Duration(days: 5475)), // ~15 years old
    );
  }

  /// Creates a fee with specific test data
  static Fee createFeeWithSpecificData({
    int? studentId,
    int? amount,
    DateTime? paymentDate,
    String? paymentMonth,
    int? paymentYear,
    String? paymentStatus,
  }) {
    return Fee(
      studentId: studentId ?? 1,
      amount: amount ?? 100,
      paymentDate: paymentDate ?? DateTime.now(),
      paymentMonth: paymentMonth ?? 'January',
      paymentYear: paymentYear ?? DateTime.now().year,
      paymentStatus: paymentStatus ?? 'Paid',
    );
  }
}

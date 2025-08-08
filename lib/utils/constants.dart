class AppConstants {
  // App name
  static const String appName = 'Arts Academy';
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // Class options
  static const List<String> classOptions = [
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11',
    'Class 12',
    'B.A Pass',
    'B.A Honours',
  ];
  
  // School options
  static const List<String> schoolOptions = [
    'BMHS',
    'CMS',
    'RKS',
  ];
  
  // Version options
  static const List<String> versionOptions = [
    'English',
    'Bengali',
  ];
  
  // Subject options
  static const List<String> subjectOptions = [
    'Bengali',
    'English',
    'History',
    'Geography',
    'Sanskrit',
    'Computer',
  ];
  
  // Database constants
  static const String databaseName = 'arts_academy.db';
  static const int databaseVersion = 1;
  
  // Tables
  static const String studentTable = 'students';
  static const String feesTable = 'fees';
  
  // Student table columns
  static const String colId = 'id';
  static const String colName = 'name';
  static const String colClass = 'class';
  static const String colSchool = 'school';
  static const String colVersion = 'version';
  static const String colGuardianName = 'guardian_name';
  static const String colGuardianPhone = 'guardian_phone';
  static const String colStudentPhone = 'student_phone';
  static const String colSubjects = 'subjects';
  static const String colFees = 'fees';
  static const String colAddress = 'address';
  static const String colAdmissionDate = 'admission_date';
  static const String colDob = 'dob';
  static const String colProfilePic = 'profile_pic';
  
  // Fees table columns
  static const String colFeeId = 'fee_id';
  static const String colStudentId = 'student_id';
  static const String colAmount = 'amount';
  static const String colPaymentDate = 'payment_date';
  static const String colPaymentMonth = 'payment_month';
  static const String colPaymentYear = 'payment_year';
  static const String colPaymentStatus = 'payment_status';
}
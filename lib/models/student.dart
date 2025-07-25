import 'package:hive/hive.dart';

part 'student.g.dart';

@HiveType(typeId: 0)
class Student extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String className;

  @HiveField(2)
  String school;

  @HiveField(3)
  String guardianPhone;

  @HiveField(4)
  String? studentPhone;

  @HiveField(5)
  String address;

  @HiveField(6)
  DateTime dob;

  @HiveField(7)
  String version; // 'english' or 'bengali'

  @HiveField(8)
  List<String> subjects;

  @HiveField(9)
  double fees;

  @HiveField(10)
  String? photoPath;

  @HiveField(11)
  DateTime admissionDate;

  @HiveField(12)
  Map<int, Set<int>> paidMonthsByYear;
  @HiveField(13)
  Map<int, Map<int, double>> paidAmountByYearMonth;
  @HiveField(14)
  Map<int, Map<int, double>> customFeeByYearMonth;

  Student({
    required this.name,
    required this.className,
    required this.school,
    required this.guardianPhone,
    this.studentPhone,
    required this.address,
    required this.dob,
    required this.version,
    required this.subjects,
    required this.fees,
    this.photoPath,
    DateTime? admissionDate,
    Map<int, Set<int>>? paidMonthsByYear,
    Map<int, Map<int, double>>? paidAmountByYearMonth,
    Map<int, Map<int, double>>? customFeeByYearMonth,
  }) :
    admissionDate = admissionDate ?? DateTime.now(),
    paidMonthsByYear = paidMonthsByYear ?? {},
    paidAmountByYearMonth = paidAmountByYearMonth ?? {},
    customFeeByYearMonth = customFeeByYearMonth ?? {};
} 
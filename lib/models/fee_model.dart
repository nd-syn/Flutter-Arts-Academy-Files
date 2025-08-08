import 'package:hive/hive.dart';

part 'fee_model.g.dart';

@HiveType(typeId: 1)
class Fee extends HiveObject {
  @HiveField(0)
  final int? id;
  
  @HiveField(1)
  final int studentId;
  
  @HiveField(2)
  final double amount;
  
  @HiveField(3)
  final DateTime paymentDate;
  
  @HiveField(4)
  final int paymentMonth;
  
  @HiveField(5)
  final int paymentYear;
  
  @HiveField(6)
  final String paymentStatus; // 'paid', 'pending', 'partial'

  Fee({
    this.id,
    required this.studentId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMonth,
    required this.paymentYear,
    required this.paymentStatus,
  });

  // Create a copy of the fee with updated fields
  Fee copyWith({
    int? id,
    int? studentId,
    double? amount,
    DateTime? paymentDate,
    int? paymentMonth,
    int? paymentYear,
    String? paymentStatus,
  }) {
    return Fee(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMonth: paymentMonth ?? this.paymentMonth,
      paymentYear: paymentYear ?? this.paymentYear,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  // Convert Fee object to a Map
  Map<String, dynamic> toMap() {
    return {
      'fee_id': id,
      'student_id': studentId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_month': paymentMonth,
      'payment_year': paymentYear,
      'payment_status': paymentStatus,
    };
  }

  // Create a Fee object from a Map
  factory Fee.fromMap(Map<String, dynamic> map) {
    return Fee(
      id: map['fee_id'],
      studentId: map['student_id'],
      amount: map['amount'],
      paymentDate: DateTime.parse(map['payment_date']),
      paymentMonth: map['payment_month'],
      paymentYear: map['payment_year'],
      paymentStatus: map['payment_status'],
    );
  }

  // Convert Fee object to JSON format
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // Create a Fee object from JSON
  static Fee fromJson(Map<String, dynamic> json) {
    return Fee.fromMap(json);
  }

  @override
  String toString() {
    return 'Fee(id: $id, studentId: $studentId, amount: $amount, paymentDate: $paymentDate, paymentMonth: $paymentMonth, paymentYear: $paymentYear, paymentStatus: $paymentStatus)';
  }
}

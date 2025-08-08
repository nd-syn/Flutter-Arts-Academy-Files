import 'dart:convert';
import 'student_model.dart';
import 'fee_model.dart';

/// Metadata class for export information
class ExportMeta {
  final String exportedAt;
  final String appVersion;
  final int schema;

  ExportMeta({
    required this.exportedAt,
    required this.appVersion,
    required this.schema,
  });

  /// Convert ExportMeta to JSON
  Map<String, dynamic> toJson() {
    return {
      'exported_at': exportedAt,
      'app_version': appVersion,
      'schema': schema,
    };
  }

  /// Create ExportMeta from JSON
  static ExportMeta fromJson(Map<String, dynamic> json) {
    return ExportMeta(
      exportedAt: json['exported_at'],
      appVersion: json['app_version'],
      schema: json['schema'],
    );
  }
}

/// Wrapper class for complete export data
class ExportData {
  final ExportMeta meta;
  final List<Student> students;
  final List<Fee> fees;

  ExportData({
    required this.meta,
    required this.students,
    required this.fees,
  });

  /// Convert ExportData to JSON
  Map<String, dynamic> toJson() {
    return {
      'meta': meta.toJson(),
      'students': students.map((student) => student.toJson()).toList(),
      'fees': fees.map((fee) => fee.toJson()).toList(),
    };
  }

  /// Create ExportData from JSON
  static ExportData fromJson(Map<String, dynamic> json) {
    return ExportData(
      meta: ExportMeta.fromJson(json['meta']),
      students: (json['students'] as List)
          .map((studentJson) => Student.fromJson(studentJson))
          .toList(),
      fees: (json['fees'] as List)
          .map((feeJson) => Fee.fromJson(feeJson))
          .toList(),
    );
  }

  /// Convert ExportData to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create ExportData from JSON string
  static ExportData fromJsonString(String jsonString) {
    return ExportData.fromJson(jsonDecode(jsonString));
  }

  /// Create export data with current timestamp and app version
  static ExportData create({
    required List<Student> students,
    required List<Fee> fees,
    String appVersion = '1.0.0',
    int schema = 1,
  }) {
    return ExportData(
      meta: ExportMeta(
        exportedAt: DateTime.now().toUtc().toIso8601String(),
        appVersion: appVersion,
        schema: schema,
      ),
      students: students,
      fees: fees,
    );
  }
}

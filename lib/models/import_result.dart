class ImportResult {
  final bool success;
  final String message;
  final int? importedStudents;
  final int? importedFees;
  final List<String> errors;

  ImportResult({
    required this.success,
    required this.message,
    this.importedStudents,
    this.importedFees,
    this.errors = const [],
  });

  ImportResult.success({
    required String message,
    int? importedStudents,
    int? importedFees,
  }) : this(
          success: true,
          message: message,
          importedStudents: importedStudents,
          importedFees: importedFees,
          errors: [],
        );

  ImportResult.error({
    required String message,
    List<String> errors = const [],
  }) : this(
          success: false,
          message: message,
          errors: errors,
        );

  @override
  String toString() {
    return 'ImportResult(success: $success, message: $message, importedStudents: $importedStudents, importedFees: $importedFees, errors: $errors)';
  }
}

import 'package:flutter/material.dart';
import '../models/student.dart';
import 'dart:io';
import 'dart:ui'; // For BackdropFilter if needed
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class StudentDetailScreen extends StatelessWidget {
  final Student student;
  const StudentDetailScreen({Key? key, required this.student}) : super(key: key);

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: width * 0.015),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: width * 0.07),
          SizedBox(width: width * 0.04),
          Text(
            '$label: ',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
              fontSize: width * 0.045,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: width * 0.045),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    // Calculate ages
    final now = DateTime.now();
    int age = now.year - student.dob.year - ((now.month < student.dob.month || (now.month == student.dob.month && now.day < student.dob.day)) ? 1 : 0);
    int admissionAge = student.admissionDate.year - student.dob.year - ((student.admissionDate.month < student.dob.month || (student.admissionDate.month == student.dob.month && student.admissionDate.day < student.dob.day)) ? 1 : 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
      ),
      body: Stack(
        children: [
          // Animated gradient background (static for now, can add animation if needed)
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
          ListView(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.04),
            children: [
              // Profile photo
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: width * 0.18,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: student.photoPath != null && student.photoPath!.isNotEmpty
                        ? FileImage(File(student.photoPath!))
                        : null,
                    child: (student.photoPath == null || student.photoPath!.isEmpty)
                        ? Icon(Icons.person, size: width * 0.18, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              SizedBox(height: width * 0.06),
              // Details card with gradient background
              Card(
                margin: const EdgeInsets.symmetric(vertical: 18),
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _tableRow(context, Icons.person, 'Name', student.name),
                      _tableRow(context, Icons.school, 'Class', student.className),
                      _tableRow(context, Icons.account_balance, 'School', student.school),
                      _tableRow(context, Icons.phone, 'Guardian Phone', student.guardianPhone),
                      if (student.studentPhone != null && student.studentPhone!.isNotEmpty)
                        _tableRow(context, Icons.phone_android, 'Student Phone', student.studentPhone!),
                      _tableRow(context, Icons.home, 'Address', student.address),
                      _tableRow(context, Icons.cake, 'DOB', student.dob.toLocal().toString().split(' ')[0]),
                      _tableRow(context, Icons.info, 'Current Age', '$age years'),
                      _tableRow(context, Icons.event_available, 'Age at Admission', '$admissionAge years'),
                      _tableRow(context, Icons.calendar_today, 'Admission Date', student.admissionDate.toLocal().toString().split(' ')[0]),
                      _tableRow(context, Icons.language, 'Version', student.version),
                      _tableRow(context, Icons.menu_book, 'Subjects', student.subjects.join(', ')),
                      _tableRow(context, Icons.attach_money, 'Fees', '₹${student.fees.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              // Payment History Section
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Payment History', style: theme.textTheme.titleLarge),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._buildPaymentHistory(context, student),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: width * 0.018),
          child: Icon(icon, color: theme.colorScheme.primary, size: width * 0.07),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: width * 0.018),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: width * 0.22, // Fixed width for label
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    fontSize: width * 0.045,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ':',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                  fontSize: width * 0.045,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.normal,
                    color: theme.colorScheme.onSurface,
                    fontSize: width * 0.045,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPaymentHistory(BuildContext context, Student student) {
    final List<Widget> rows = [];
    final theme = Theme.of(context);
    final history = <Map<String, dynamic>>[];
    student.paidAmountByYearMonth.forEach((year, monthMap) {
      monthMap.forEach((month, amount) {
        final fee = student.customFeeByYearMonth[year]?[month] ?? student.fees;
        history.add({
          'year': year,
          'month': month,
          'amount': amount,
          'fee': fee,
          'status': amount >= fee ? 'Paid' : (amount > 0 ? 'Partial' : 'Unpaid'),
          'date': DateTime(year, month, 1),
        });
      });
    });
    history.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    for (final entry in history) {
      rows.add(
        ListTile(
          leading: Icon(
            entry['status'] == 'Paid' ? Icons.check_circle : (entry['status'] == 'Partial' ? Icons.timelapse : Icons.warning_amber_rounded),
            color: entry['status'] == 'Paid' ? Colors.green : (entry['status'] == 'Partial' ? Colors.purple : Colors.red),
          ),
          title: Text('${entry['month']}/${entry['year']} - ₹${entry['amount'].toStringAsFixed(2)} / ₹${entry['fee'].toStringAsFixed(2)}'),
          subtitle: Text('Status: ${entry['status']}'),
          trailing: ElevatedButton.icon(
            icon: const Icon(Icons.receipt_long, size: 16),
            label: const Text('Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            onPressed: () async {
              await _generateAndShareReceipt(context, student, entry);
            },
          ),
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(const Text('No payments yet.', style: TextStyle(color: Colors.grey)));
    }
    return rows;
  }

  Future<void> _generateAndShareReceipt(BuildContext context, Student student, Map<String, dynamic> entry) async {
    final pdf = pw.Document();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Payment Receipt', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Text('Student Name: ${student.name}', style: pw.TextStyle(fontSize: 18)),
                pw.Text('Class: ${student.className}', style: pw.TextStyle(fontSize: 16)),
                pw.Text('School: ${student.school}', style: pw.TextStyle(fontSize: 16)),
                pw.Text('Guardian Phone: ${student.guardianPhone}', style: pw.TextStyle(fontSize: 16)),
                if (student.studentPhone != null && student.studentPhone!.isNotEmpty)
                  pw.Text('Student Phone: ${student.studentPhone}', style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 12),
                pw.Text('Receipt for: ${monthNames[(entry['month'] as int) - 1]} ${entry['year']}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Amount Paid: ₹${(entry['amount'] as double).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                pw.Text('Total Fee: ₹${(entry['fee'] as double).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                pw.Text('Status: ${entry['status']}', style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 12),
                pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}', style: pw.TextStyle(fontSize: 14)),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text('Thank you for your payment!', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Arts Academy', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Receipt_${student.name}_${entry['month']}_${entry['year']}.pdf');
  }
} 
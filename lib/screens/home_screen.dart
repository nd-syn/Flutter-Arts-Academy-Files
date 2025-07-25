import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/student.dart';
import '../db/student_db.dart';
import '../widgets/student_card.dart';
import 'add_edit_student_screen.dart';
import 'student_detail_screen.dart';
import '../widgets/confirm_dialog.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Student> studentBox;
  String sortBy = 'name';
  bool ascending = true;

  @override
  void initState() {
    super.initState();
    studentBox = Hive.box<Student>('students');
  }

  void _addOrEditStudent({Student? student, int? index}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditStudentScreen(student: student, index: index),
      ),
    );
    setState(() {});
  }

  void _viewStudent(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(student: student),
      ),
    );
  }

  void _deleteStudent(int index) async {
    await StudentDB.deleteStudent(index);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 12),
              Text('Student deleted!'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  List<Student> _getSortedStudents() {
    List<Student> students = studentBox.values.toList();
    students.sort((a, b) {
      int cmp;
      switch (sortBy) {
        case 'date':
          cmp = a.dob.compareTo(b.dob);
          break;
        case 'course':
          cmp = a.className.compareTo(b.className);
          break;
        case 'name':
        default:
          cmp = a.name.compareTo(b.name);
      }
      return ascending ? cmp : -cmp;
    });
    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ArtsAcademy'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Dashboard',
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          ),
          Switch(
            value: themeModeNotifier.value == ThemeMode.dark,
            onChanged: (val) => themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveThumbColor: Colors.grey,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'asc' || value == 'desc') {
                setState(() => ascending = value == 'asc');
              } else {
                setState(() => sortBy = value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'course', child: Text('Sort by Course')),
              const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'asc', child: Text('Ascending')),
              const PopupMenuItem(value: 'desc', child: Text('Descending')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
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
          ValueListenableBuilder(
            valueListenable: studentBox.listenable(),
            builder: (context, Box<Student> box, _) {
              final students = _getSortedStudents();
              if (students.isEmpty) {
                return Center(
                  child: Text(
                    'No students yet. Tap + to add.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                );
              }
              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Dismissible(
                    key: Key(student.key.toString()),
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      final confirmed = await showConfirmDialog(
                        context: context,
                        title: 'Delete Student',
                        message: 'Are you sure you want to delete this student? This action cannot be undone.',
                        icon: Icons.delete_forever,
                        confirmText: 'Delete',
                        confirmColor: Colors.redAccent,
                      );
                      if (confirmed == true) {
                        _deleteStudent(index);
                        return true;
                      }
                      return false;
                    },
                    child: RepaintBoundary(
                      child: StudentCard(
                        name: student.name,
                        className: student.className,
                        photoPath: student.photoPath,
                        onTap: () => _viewStudent(student),
                        onEdit: () => _addOrEditStudent(student: student, index: index),
                        version: student.version,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.08),
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        onEnd: () {
          // Loop the animation
          setState(() {});
        },
        child: FloatingActionButton(
          onPressed: () => _addOrEditStudent(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
} 
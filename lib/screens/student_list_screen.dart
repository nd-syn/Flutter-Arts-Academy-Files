import 'package:flutter/material.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/screens/add_student_screen.dart';
import 'package:arts_academy/screens/edit_student_screen.dart';
import 'package:arts_academy/screens/student_detail_screen.dart';
import 'package:arts_academy/services/database_helper.dart';
import 'package:arts_academy/utils/theme.dart';
import 'package:arts_academy/widgets/student_card.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSortFilter = 'All'; // All, Class, Subject, Version, School, Fee Range
  String? _selectedFilterValue; // The actual value selected from dropdown
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final students = await _databaseHelper.getStudents();
      setState(() {
        _allStudents = students;
        _filteredStudents = students;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load students: $e');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onSortFilterChanged(String filter) {
    if (filter == 'All') {
      setState(() {
        _selectedSortFilter = filter;
        _selectedFilterValue = null;
      });
      _applyFilters();
    } else {
      _showFilterDropdown(filter);
    }
  }
  
  void _showFilterDropdown(String filterType) {
    List<String> options = [];
    
    switch (filterType) {
      case 'Class':
        options = _getUniqueValues((s) => s.studentClass).toList()..sort();
        break;
      case 'Subject':
        // Get all unique subjects from all students
        Set<String> allSubjects = {};
        for (Student student in _allStudents) {
          allSubjects.addAll(student.subjects);
        }
        options = allSubjects.toList()..sort();
        break;
      case 'Version':
        options = _getUniqueValues((s) => s.version).toList()..sort();
        break;
      case 'School':
        options = _getUniqueValues((s) => s.school).toList()..sort();
        break;
      case 'Fees':
        // For fees, we'll show a custom dialog instead of using the dropdown
        _showFeesFilterDialog();
        return;
    }
    
    if (options.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by $filterType'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length + 1, // +1 for "Show All" option
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "Show All" option
                  return ListTile(
                    leading: Icon(Icons.clear_all, color: AppTheme.primaryColor),
                    title: const Text('Show All'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedSortFilter = 'All';
                        _selectedFilterValue = null;
                      });
                      _applyFilters();
                    },
                  );
                }
                
                final option = options[index - 1];
                return ListTile(
                  leading: _getFilterIcon(filterType),
                  title: Text(option),
                  trailing: _selectedFilterValue == option 
                      ? Icon(Icons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedSortFilter = filterType;
                      _selectedFilterValue = option;
                    });
                    _applyFilters();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  void _showFeesFilterDialog() {
    final TextEditingController exactController = TextEditingController();
    String selectedOption = 'Exact'; // Exact, Low to High, High to Low
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.currency_rupee_rounded, color: const Color(0xFF4CAF50), size: 24),
                  const SizedBox(width: 8),
                  const Text('Filter by Fees'),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Options
                    const Text(
                      'Filter Type:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Radio buttons for filter type
                    Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Exact Amount'),
                          value: 'Exact',
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedOption = value!;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<String>(
                          title: const Text('Low to High'),
                          value: 'Low to High',
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedOption = value!;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<String>(
                          title: const Text('High to Low'),
                          value: 'High to Low',
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedOption = value!;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    
                    // Exact amount input field (only show when Exact is selected)
                    if (selectedOption == 'Exact') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Exact Fee Amount:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: exactController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Fee Amount',
                          hintText: 'Enter exact amount',
                          prefixText: '₹',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedSortFilter = 'All';
                      _selectedFilterValue = null;
                    });
                    _applyFilters();
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String filterValue = selectedOption;
                    
                    if (selectedOption == 'Exact') {
                      final exactText = exactController.text.trim();
                      
                      if (exactText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter the exact amount')),
                        );
                        return;
                      }
                      
                      final exactAmount = double.tryParse(exactText);
                      
                      if (exactAmount == null || exactAmount < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid positive amount')),
                        );
                        return;
                      }
                      
                      // Create exact amount filter value
                      filterValue = '₹${exactAmount.toInt()}';
                    }
                    
                    Navigator.pop(context);
                    setState(() {
                      _selectedSortFilter = 'Fees';
                      _selectedFilterValue = filterValue;
                    });
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Icon _getFilterIcon(String filterType) {
    switch (filterType) {
      case 'Class':
        return Icon(Icons.school_rounded, color: const Color(0xFF2196F3), size: 20);
      case 'Subject':
        return Icon(Icons.book_rounded, color: const Color(0xFF9C27B0), size: 20);
      case 'Version':
        return Icon(Icons.bookmark_rounded, color: const Color(0xFFFF5722), size: 20);
      case 'School':
        return Icon(Icons.location_city_rounded, color: const Color(0xFF607D8B), size: 20);
      case 'Fees':
        return Icon(Icons.currency_rupee_rounded, color: const Color(0xFF4CAF50), size: 20);
      default:
        return Icon(Icons.filter_list, color: AppTheme.primaryColor, size: 20);
    }
  }

  void _applyFilters() {
    List<Student> filtered = List.from(_allStudents);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((student) {
        return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               student.studentClass.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               student.school.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               student.version.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               student.subjects.any((subject) => subject.toLowerCase().contains(_searchQuery.toLowerCase())) ||
               student.guardianName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply specific filter based on selected filter type and value
    if (_selectedSortFilter != 'All' && _selectedFilterValue != null) {
      switch (_selectedSortFilter) {
        case 'Class':
          filtered = filtered.where((student) => student.studentClass == _selectedFilterValue).toList();
          break;
        case 'Subject':
          filtered = filtered.where((student) => student.subjects.contains(_selectedFilterValue)).toList();
          break;
        case 'Version':
          filtered = filtered.where((student) => student.version == _selectedFilterValue).toList();
          break;
        case 'School':
          filtered = filtered.where((student) => student.school == _selectedFilterValue).toList();
          break;
        case 'Fees':
          filtered = _applyFeeFilter(filtered, _selectedFilterValue!);
          break;
      }
    }
    
    setState(() {
      _filteredStudents = filtered;
    });
  }
  
  List<Student> _applyFeeFilter(List<Student> students, String filterValue) {
    switch (filterValue) {
      case 'Low to High':
        students.sort((a, b) => a.fees.compareTo(b.fees));
        return students;
      case 'High to Low':
        students.sort((a, b) => b.fees.compareTo(a.fees));
        return students;
      default:
        // Handle exact amount filter
        if (filterValue.startsWith('₹') && !filterValue.contains('-') && !filterValue.contains('≥') && !filterValue.contains('≤')) {
          // Exact amount filter like "₹1500"
          final amountStr = filterValue.replaceAll('₹', '').trim();
          final exactAmount = double.tryParse(amountStr);
          if (exactAmount != null) {
            return students.where((s) => s.fees == exactAmount).toList();
          }
        }
        // Handle custom ranges (keeping for backward compatibility)
        else if (filterValue.contains('-')) {
          // Range filter like "₹1000-₹2000"
          final parts = filterValue.split('-');
          if (parts.length == 2) {
            final minStr = parts[0].replaceAll('₹', '').trim();
            final maxStr = parts[1].replaceAll('₹', '').trim();
            final minAmount = double.tryParse(minStr);
            final maxAmount = double.tryParse(maxStr);
            
            if (minAmount != null && maxAmount != null) {
              return students.where((s) => s.fees >= minAmount && s.fees <= maxAmount).toList();
            }
          }
        } else if (filterValue.startsWith('≥')) {
          // Minimum only filter like "≥ ₹1000"
          final amountStr = filterValue.replaceAll('≥', '').replaceAll('₹', '').trim();
          final minAmount = double.tryParse(amountStr);
          if (minAmount != null) {
            return students.where((s) => s.fees >= minAmount).toList();
          }
        } else if (filterValue.startsWith('≤')) {
          // Maximum only filter like "≤ ₹5000"
          final amountStr = filterValue.replaceAll('≤', '').replaceAll('₹', '').trim();
          final maxAmount = double.tryParse(amountStr);
          if (maxAmount != null) {
            return students.where((s) => s.fees <= maxAmount).toList();
          }
        }
        return students;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _deleteStudent(Student student) async {
    try {
      await _databaseHelper.deleteStudent(student.id!);
      setState(() {
        _allStudents.removeWhere((s) => s.id == student.id);
      });
      _applyFilters(); // Refresh filtered list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.name} deleted successfully'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete student: $e');
    }
  }

  Future<void> _confirmDelete(Student student) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent(student);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.8),
              Colors.white.withOpacity(0.95),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allStudents.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      _buildSearchAndFilterHeader(),
                      Expanded(child: _buildStudentList()),
                    ],
                  ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Position above navbar
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddStudentScreen(),
              ),
            );
            if (result == true) {
              _loadStudents();
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Student'),
          backgroundColor: AppTheme.accentColor,
          elevation: 6,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Students Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first student by tapping the button below',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddStudentScreen(),
                ),
              );
              if (result == true) {
                _loadStudents();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Student'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return RefreshIndicator(
      onRefresh: _loadStudents,
      color: AppTheme.primaryColor,
      child: AnimationLimiter(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _filteredStudents.length,
          itemBuilder: (context, index) {
            final student = _filteredStudents[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: StudentCard(
                      student: student,
                      index: index,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentDetailScreen(student: student),
                          ),
                        );
                      },
                      onEdit: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditStudentScreen(student: student),
                          ),
                        );
                        if (result == true) {
                          _loadStudents();
                        }
                      },
                      onDelete: () => _confirmDelete(student),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and search action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title and count
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_filteredStudents.length} of ${_allStudents.length} students',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // Search toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) {
                      _searchController.clear();
                      _onSearchChanged('');
                    }
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isSearchVisible
                        ? AppTheme.primaryColor
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _isSearchVisible
                            ? AppTheme.primaryColor.withOpacity(0.25)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
                    color: _isSearchVisible
                        ? Colors.white
                        : AppTheme.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Search Bar (Animated)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSearchVisible ? 52 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isSearchVisible ? 1.0 : 0.0,
              child: _isSearchVisible
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _searchQuery.isNotEmpty
                              ? AppTheme.primaryColor.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        autofocus: _isSearchVisible,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              Icons.search_rounded,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.textSecondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: AppTheme.textSecondary,
                                      size: 16,
                                    ),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          
          if (_isSearchVisible) const SizedBox(height: 16),
          
          // Filter Tabs
          Container(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFilterTab('All', Icons.apps_rounded, _allStudents.length),
                const SizedBox(width: 12),
                _buildFilterTab('Class', Icons.school_rounded, _getUniqueValues((s) => s.studentClass).length),
                const SizedBox(width: 12),
                _buildFilterTab('Subject', Icons.book_rounded, _getUniqueValues((s) => s.subjects.isNotEmpty ? s.subjects[0] : '').length),
                const SizedBox(width: 12),
                _buildFilterTab('Version', Icons.bookmark_rounded, _getUniqueValues((s) => s.version).length),
                const SizedBox(width: 12),
                _buildFilterTab('School', Icons.location_city_rounded, _getUniqueValues((s) => s.school).length),
                const SizedBox(width: 12),
                _buildFilterTab('Fees', Icons.currency_rupee_rounded, _allStudents.length),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Set<String> _getUniqueValues(String Function(Student) getValue) {
    return _allStudents.map(getValue).where((value) => value.isNotEmpty).toSet();
  }

  Widget _buildFilterTab(String label, IconData icon, int count) {
    final bool isSelected = _selectedSortFilter == label;
    
    // Define colors based on filter type and selection state
    Color backgroundColor, textColor, iconColor, countBgColor, countTextColor;
    
    if (isSelected) {
      switch (label) {
        case 'Class':
          backgroundColor = const Color(0xFF2196F3);
          textColor = Colors.white;
          iconColor = Colors.white;
          countBgColor = Colors.white.withOpacity(0.25);
          countTextColor = Colors.white;
          break;
        case 'Subject':
          backgroundColor = const Color(0xFF9C27B0);
          textColor = Colors.white;
          iconColor = Colors.white;
          countBgColor = Colors.white.withOpacity(0.25);
          countTextColor = Colors.white;
          break;
        case 'Version':
          backgroundColor = const Color(0xFFFF5722);
          textColor = Colors.white;
          iconColor = Colors.white;
          countBgColor = Colors.white.withOpacity(0.25);
          countTextColor = Colors.white;
          break;
        case 'School':
          backgroundColor = const Color(0xFF607D8B);
          textColor = Colors.white;
          iconColor = Colors.white;
          countBgColor = Colors.white.withOpacity(0.25);
          countTextColor = Colors.white;
          break;
        case 'Fees':
          backgroundColor = const Color(0xFF4CAF50);
          textColor = Colors.white;
          iconColor = Colors.white;
          countBgColor = Colors.white.withOpacity(0.25);
          countTextColor = Colors.white;
          break;
        default: // All
          backgroundColor = AppTheme.primaryColor;
          textColor = Colors.white;
          iconColor = Colors.white;
          countBgColor = Colors.white.withOpacity(0.25);
          countTextColor = Colors.white;
      }
    } else {
      backgroundColor = AppTheme.cardBackground;
      textColor = AppTheme.textSecondary;
      iconColor = AppTheme.textSecondary;
      countBgColor = AppTheme.textSecondary.withOpacity(0.1);
      countTextColor = AppTheme.textSecondary;
    }
    
    return GestureDetector(
      onTap: () => _onSortFilterChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: countBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: countTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
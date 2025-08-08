import 'package:flutter/material.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/utils/theme.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

class StudentCard extends StatefulWidget {
  final Student student;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int index;

  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.index = 0,
  });

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppTheme.bounceCurve,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppTheme.standardCurve,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }
  
  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onTap();
  }
  
  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: widget.index,
      duration: AppTheme.slowAnimation,
      child: SlideAnimation(
        curve: AppTheme.slideCurve,
        child: FadeInAnimation(
          curve: AppTheme.standardCurve,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => Transform.scale(
              scale: _isPressed ? 0.98 : _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.04, 
                    vertical: 6,
                  ),
                  child: Slidable(
                    key: ValueKey('student_${widget.student.id}'),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.35, // Increased for better visibility
                      children: [
                        SlidableAction(
                          onPressed: (_) => _animateAndExecute(widget.onEdit),
                          backgroundColor: AppTheme.info,
                          foregroundColor: AppTheme.textOnPrimary,
                          icon: Icons.edit_rounded,
                          label: 'Edit',
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                        ),
                        SlidableAction(
                          onPressed: (_) => _animateAndExecute(widget.onDelete),
                          backgroundColor: AppTheme.error,
                          foregroundColor: AppTheme.textOnPrimary,
                          icon: Icons.delete_rounded,
                          label: 'Delete',
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTapDown: _handleTapDown,
                      onTapUp: _handleTapUp,
                      onTapCancel: _handleTapCancel,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.cardBackground,
                              AppTheme.cardBackground.withOpacity(0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: _isPressed 
                            ? AppTheme.softShadow 
                            : AppTheme.mediumShadow,
                          border: Border.all(
                            color: AppTheme.textLight.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04), // Responsive padding
                          child: Row(
                            children: [
                              // Enhanced Profile Picture/Avatar
                              _buildProfileAvatar(),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                              
                              // Student Information
                              Expanded(
                                child: _buildStudentInfo(),
                              ),
                              
                              // Enhanced Fee Badge (responsive)
                              _buildFeeBadge(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileAvatar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarSize = screenWidth < 360 ? 56.0 : 64.0; // Responsive avatar size
    
    return Hero(
      tag: 'student_avatar_${widget.student.id}',
      child: Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: widget.student.profilePic != null 
            ? null 
            : AppTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          image: widget.student.profilePic != null
            ? DecorationImage(
                image: MemoryImage(widget.student.profilePic!),
                fit: BoxFit.cover,
              )
            : null,
        ),
        child: widget.student.profilePic == null
          ? Center(
              child: Text(
                widget.student.name.isNotEmpty
                  ? widget.student.name[0].toUpperCase()
                  : '?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
      ),
    );
  }
  
  Widget _buildStudentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Name
        Text(
          widget.student.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        
        // Class and School with icons
        Row(
          children: [
            Icon(
              Icons.school_outlined,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${widget.student.studentClass} • ${widget.student.school}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Admission Date with icon
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppTheme.textLight,
            ),
            const SizedBox(width: 6),
            Text(
              'Joined ${DateFormat('MMM yyyy').format(widget.student.admissionDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Subject count indicator
        Row(
          children: [
            Icon(
              Icons.subject_outlined,
              size: 14,
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.student.subjects.length} subject${widget.student.subjects.length != 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFeeBadge() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16, 
        vertical: isSmallScreen ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.currency_rupee_rounded,
            size: isSmallScreen ? 16 : 18,
            color: AppTheme.textOnPrimary,
          ),
          SizedBox(height: isSmallScreen ? 1 : 2),
          Text(
            widget.student.fees.toInt().toString(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textOnPrimary,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          Text(
            'monthly',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textOnPrimary.withOpacity(0.8),
              fontSize: isSmallScreen ? 8 : 9,
            ),
          ),
        ],
      ),
    );
  }
  
  void _animateAndExecute(VoidCallback callback) async {
    await _animationController.reverse();
    callback();
    _animationController.forward();
  }
}
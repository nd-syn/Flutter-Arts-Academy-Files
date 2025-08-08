import 'package:flutter/material.dart';
import 'package:arts_academy/utils/theme.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  
  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Students',
      color: AppTheme.primaryColor,
    ),
    NavItem(
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
      label: 'Fees',
      color: AppTheme.accentColor,
    ),
    NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Overview',
      color: AppTheme.info,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppTheme.bounceCurve,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 70, // Fixed compact height
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
            boxShadow: AppTheme.mediumShadow, // Use medium shadow instead of strong
            border: Border.all(
              color: AppTheme.textLight.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(
                  _navItems[index],
                  index,
                  widget.currentIndex == index,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(NavItem item, int index, bool isSelected) {
    return AnimatedContainer(
      duration: AppTheme.mediumAnimation,
      curve: AppTheme.standardCurve,
      child: InkWell(
        onTap: () {
          _animationController.reverse().then((_) {
            widget.onTap(index);
            _animationController.forward();
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: isSelected 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color,
                    item.color.withOpacity(0.8),
                  ],
                )
              : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: item.color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppTheme.fastAnimation,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey(isSelected),
                  color: isSelected 
                    ? AppTheme.textOnPrimary 
                    : AppTheme.textLight,
                  size: isSelected ? 22 : 20,
                ),
              ),
              AnimatedContainer(
                duration: AppTheme.mediumAnimation,
                curve: AppTheme.standardCurve,
                width: isSelected ? 6 : 0,
              ),
              AnimatedContainer(
                duration: AppTheme.mediumAnimation,
                curve: AppTheme.standardCurve,
                width: isSelected ? null : 0,
                child: AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: AppTheme.mediumAnimation,
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.textOnPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomNavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../friends/screens/friends_screen.dart';
import '../home/screens/home_screen.dart';
import '../map/screens/map_screen.dart';
import '../profile/screens/profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialTab;

  const MainNavigationShell({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigateToMap: () => _onItemTapped(1),
          ),
          MapScreen(
            key: _mapKey,
            onNavigateToHome: () => _onItemTapped(0),
          ),
          const FriendsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  Widget _buildGlassBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: SafeArea(
            top: false,
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  _navItem(
                    index: 1,
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map_rounded,
                    label: 'Map',
                  ),
                  _navItem(
                    index: 2,
                    icon: Icons.group_outlined,
                    activeIcon: Icons.group_rounded,
                    label: 'Friends',
                  ),
                  _navItem(
                    index: 3,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color:
                  isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

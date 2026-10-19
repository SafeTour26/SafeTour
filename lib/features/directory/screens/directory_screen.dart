import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../data/models/safety_zone.dart';
import '../../../data/repositories/safety_zone_repository.dart';
import '../../map/widgets/locality_bottom_sheet.dart';
import '../widgets/locality_card.dart';

enum LocalityFilter {
  all,
  safest,
  nightSafe,
  caution,
}

enum LocalitySort {
  scoreDesc,
  scoreAsc,
  nameAsc,
  distanceAsc,
}

class DirectoryScreen extends StatefulWidget {
  final Function(SafetyZone)? onSelectZoneOnMap;

  const DirectoryScreen({
    super.key,
    this.onSelectZoneOnMap,
  });

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final SafetyZoneRepository _zoneRepo = SafetyZoneRepository();
  final TextEditingController _searchController = TextEditingController();

  List<SafetyZone> _allZones = [];
  List<SafetyZone> _filteredZones = [];
  bool _isLoading = true;
  Position? _currentPosition;

  LocalityFilter _selectedFilter = LocalityFilter.all;
  LocalitySort _selectedSort = LocalitySort.scoreDesc;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchZones(),
      _getUserLocation(),
    ]);
    _applyFiltersAndSort();
  }

  Future<void> _fetchZones() async {
    try {
      final zones = await _zoneRepo.getSafetyZones();
      if (mounted) {
        setState(() {
          _allZones = zones;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.whileInUse ||
          hasPermission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        if (mounted) {
          setState(() => _currentPosition = position);
        }
      }
    } catch (_) {}
  }

  void _applyFiltersAndSort() {
    final query = _searchController.text.trim().toLowerCase();

    var results = _allZones.where((zone) {
      // Text search
      final matchesQuery = query.isEmpty ||
          zone.areaName.toLowerCase().contains(query) ||
          zone.safetyTips.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      // Filter chips
      switch (_selectedFilter) {
        case LocalityFilter.safest:
          return zone.overallScore >= 8.0;
        case LocalityFilter.nightSafe:
          return zone.nightScore >= 7.5;
        case LocalityFilter.caution:
          return zone.overallScore < 6.0;
        case LocalityFilter.all:
          return true;
      }
    }).toList();

    // Sorting
    switch (_selectedSort) {
      case LocalitySort.scoreDesc:
        results.sort((a, b) => b.overallScore.compareTo(a.overallScore));
        break;
      case LocalitySort.scoreAsc:
        results.sort((a, b) => a.overallScore.compareTo(b.overallScore));
        break;
      case LocalitySort.nameAsc:
        results.sort((a, b) => a.areaName.compareTo(b.areaName));
        break;
      case LocalitySort.distanceAsc:
        if (_currentPosition != null) {
          results.sort((a, b) {
            final distA = DistanceFormatter.calculateDistanceMeters(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              a.latitude,
              a.longitude,
            );
            final distB = DistanceFormatter.calculateDistanceMeters(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              b.latitude,
              b.longitude,
            );
            return distA.compareTo(distB);
          });
        }
        break;
    }

    setState(() {
      _filteredZones = results;
    });
  }

  double? _calculateDistance(SafetyZone zone) {
    if (_currentPosition == null) return null;
    return DistanceFormatter.calculateDistanceMeters(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      zone.latitude,
      zone.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bengaluru Safety Directory',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_allZones.length} verified localities • Updated live',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<LocalitySort>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.onSurface),
            tooltip: 'Sort localities',
            color: AppColors.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            initialValue: _selectedSort,
            onSelected: (sort) {
              setState(() => _selectedSort = sort);
              _applyFiltersAndSort();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: LocalitySort.scoreDesc,
                child: Text('Safety Score: High to Low'),
              ),
              const PopupMenuItem(
                value: LocalitySort.scoreAsc,
                child: Text('Safety Score: Low to High'),
              ),
              const PopupMenuItem(
                value: LocalitySort.nameAsc,
                child: Text('Alphabetical (A - Z)'),
              ),
              if (_currentPosition != null)
                const PopupMenuItem(
                  value: LocalitySort.distanceAsc,
                  child: Text('Distance: Closest First'),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 56px Pill Search Box (design.md specification)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurface),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText:
                            'Search locality (e.g. Indiranagar, Whitefield)...',
                        hintStyle: AppTypography.bodyMd.copyWith(
                          color:
                              AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => _applyFiltersAndSort(),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _applyFiltersAndSort();
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Filter Chips Horizontal Bar
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip(
                  label: 'All (${_allZones.length})',
                  filter: LocalityFilter.all,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Safest (≥ 8.0)',
                  filter: LocalityFilter.safest,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Night Safe (≥ 7.5)',
                  filter: LocalityFilter.nightSafe,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Caution (< 6.0)',
                  filter: LocalityFilter.caution,
                  color: AppColors.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Locality List View
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filteredZones.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchZones,
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceContainerLow,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: _filteredZones.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final zone = _filteredZones[index];
                            final distance = _calculateDistance(zone);

                            return LocalityCard(
                              zone: zone,
                              distanceMeters: distance,
                              onTap: () {
                                LocalityBottomSheet.show(
                                  context,
                                  zone,
                                  onFocusOnMap: widget.onSelectZoneOnMap != null
                                      ? () => widget.onSelectZoneOnMap!(zone)
                                      : null,
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required LocalityFilter filter,
    Color? color,
  }) {
    final isSelected = _selectedFilter == filter;
    final activeColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
        _applyFiltersAndSort();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.2)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? activeColor
                : AppColors.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 32,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Localities Found',
              style: AppTypography.headlineSm.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your search terms or selecting another safety filter.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedFilter = LocalityFilter.all;
                });
                _applyFiltersAndSort();
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

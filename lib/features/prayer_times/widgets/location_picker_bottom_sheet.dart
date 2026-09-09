// lib/features/prayer_times/widgets/location_picker_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../services/location_search_service.dart';
import '../services/prayer_service.dart';

class LocationPickerBottomSheet extends ConsumerStatefulWidget {
  const LocationPickerBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LocationPickerBottomSheet(),
    );
  }

  @override
  ConsumerState<LocationPickerBottomSheet> createState() => _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState extends ConsumerState<LocationPickerBottomSheet> {
  final _searchCtrl = TextEditingController();
  List<CityLocation> _results = LocationSearchService.popularCities;
  bool _searching = false;
  bool _gettingGps = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _searching = true);
    final list = await LocationSearchService.searchLocations(query);
    if (mounted) {
      setState(() {
        _results = list;
        _searching = false;
      });
    }
  }

  Future<void> _useGpsLocation() async {
    setState(() => _gettingGps = true);
    final gpsLoc = await LocationSearchService.getCurrentGpsLocation();
    if (mounted) {
      setState(() => _gettingGps = false);
      if (gpsLoc != null) {
        ref.read(selectedLocationProvider.notifier).setLocation(gpsLoc);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location updated to ${gpsLoc.displayName}'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not obtain GPS location. Please select a city manually.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = ref.watch(selectedLocationProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Location',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Text(
                            'For accurate Namaz prayer times & Qibla',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search field
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    if (val.length >= 2 || val.isEmpty) {
                      _performSearch(val);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search city anywhere in the world...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.primary),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // GPS Auto-detect button
                InkWell(
                  onTap: _gettingGps ? null : _useGpsLocation,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _gettingGps
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                              )
                            : const Icon(Icons.my_location, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _gettingGps ? 'Locating...' : 'Use Current GPS Location',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // City list
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          'No cities found for "${_searchCtrl.text}"',
                          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.only(bottom: 16 + MediaQuery.paddingOf(context).bottom),
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (ctx, idx) {
                          final loc = _results[idx];
                          final isSelected = loc.cityName.toLowerCase() == currentLocation.cityName.toLowerCase() &&
                              (loc.countryName.isEmpty || loc.countryName.toLowerCase() == currentLocation.countryName.toLowerCase());

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: isSelected ? AppTheme.primary : AppTheme.primarySurface,
                              child: Icon(
                                Icons.location_city,
                                color: isSelected ? Colors.white : AppTheme.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              loc.cityName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: loc.countryName.isNotEmpty
                                ? Text(
                                    loc.countryName,
                                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                                  )
                                : null,
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                                : null,
                            onTap: () {
                              ref.read(selectedLocationProvider.notifier).setLocation(loc);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Location set to ${loc.displayName}'),
                                  backgroundColor: AppTheme.primary,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

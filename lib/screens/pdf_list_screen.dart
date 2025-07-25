import 'package:flutter/material.dart';

import '../widgets/pdf_thumbnail_card.dart';
import '../models/pdf_asset.dart';
import '../models/epaper_metadata.dart';
import '../services/pdf_service.dart';
import 'pdf_viewer_screen.dart';

class PdfListScreen extends StatefulWidget {
  const PdfListScreen({super.key});

  @override
  State<PdfListScreen> createState() => _PdfListScreenState();
}

class _PdfListScreenState extends State<PdfListScreen> {
  final PdfService _pdfService = PdfService();
  List<PdfAsset> _pdfAssets = [];
  List<PdfAsset> _filteredPdfAssets = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedRegion;
  EpaperType? _selectedType;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Set default date range to 1 week back
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 7));
    _loadPdfAssets();
  }

  Future<void> _loadPdfAssets() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final assets = await _pdfService.getPdfList();
      
      setState(() {
        _pdfAssets = assets;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load PDF list: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredPdfAssets = _pdfAssets.where((asset) {
      // Date filter
      if (_startDate != null && _endDate != null) {
        final publishDate = asset.publishDate;
        if (publishDate.isBefore(_startDate!) || publishDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Region filter
      if (_selectedRegion != null && _selectedRegion!.isNotEmpty) {
        final region = asset.epaperMetadata?.region;
        if (region == null || region != _selectedRegion) {
          return false;
        }
      }

      // Type filter
      if (_selectedType != null) {
        final type = asset.epaperMetadata?.type;
        if (type == null || type != _selectedType) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by publish date (newest first)
    _filteredPdfAssets.sort((a, b) {
      return b.publishDate.compareTo(a.publishDate);
    });
  }

  List<String> _getAvailableRegions() {
    final regions = _pdfAssets
        .map((asset) => asset.epaperMetadata?.region)
        .where((region) => region != null)
        .cast<String>()
        .toSet()
        .toList();
    regions.sort();
    return regions;
  }

  List<EpaperType> _getAvailableTypes() {
    final types = _pdfAssets
        .map((asset) => asset.epaperMetadata?.type)
        .where((type) => type != null)
        .cast<EpaperType>()
        .toSet()
        .toList();
    types.sort((a, b) => a.displayName.compareTo(b.displayName));
    return types;
  }

  void _resetFilters() {
    setState(() {
      final now = DateTime.now();
      _startDate = now.subtract(const Duration(days: 7));
      _endDate = now;
      _selectedRegion = null;
      _selectedType = null;
      _applyFilters();
    });
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _applyFilters();
    });
  }

  bool _hasActiveFilters() {
    // Check if any non-default filters are active
    final now = DateTime.now();
    final defaultStart = now.subtract(const Duration(days: 7));
    final defaultEnd = now;
    
    bool hasCustomDateRange = false;
    if (_startDate != null && _endDate != null) {
      hasCustomDateRange = !(_startDate!.isAtSameMomentAs(defaultStart) && 
                           _endDate!.isAtSameMomentAs(defaultEnd));
    } else if (_startDate != null || _endDate != null) {
      hasCustomDateRange = true;
    }
    
    return hasCustomDateRange || 
           _selectedRegion != null || 
           _selectedType != null;
  }

  int _getActiveFilterCount() {
    int count = 0;
    
    // Count date filter as active if it's not the default 1-week range
    final now = DateTime.now();
    final defaultStart = now.subtract(const Duration(days: 7));
    final defaultEnd = now;
    
    if (_startDate != null && _endDate != null) {
      if (!(_startDate!.isAtSameMomentAs(defaultStart) && 
            _endDate!.isAtSameMomentAs(defaultEnd))) {
        count++;
      }
    } else if (_startDate != null || _endDate != null) {
      count++;
    }
    
    if (_selectedRegion != null) count++;
    if (_selectedType != null) count++;
    
    return count;
  }

  Widget _buildQuickFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Active Filters:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showFilters = true;
                  });
                },
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Date range chip
              if (_startDate != null || _endDate != null) _buildDateRangeChip(),
              // Region chip
              if (_selectedRegion != null) _buildRegionChip(),
              // Type chip
              if (_selectedType != null) _buildTypeChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip() {
    String label;
    if (_startDate != null && _endDate != null) {
      label = '${_startDate!.day}.${_startDate!.month} - ${_endDate!.day}.${_endDate!.month}';
    } else if (_startDate != null) {
      label = 'From ${_startDate!.day}.${_startDate!.month}';
    } else if (_endDate != null) {
      label = 'Until ${_endDate!.day}.${_endDate!.month}';
    } else {
      label = 'Date Range';
    }

    return Chip(
      avatar: Icon(
        Icons.date_range,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(label),
      onDeleted: () {
        setState(() {
          final now = DateTime.now();
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          _applyFilters();
        });
      },
      deleteIcon: const Icon(Icons.close, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildRegionChip() {
    return Chip(
      avatar: Icon(
        Icons.location_on,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(_selectedRegion!),
      onDeleted: () {
        setState(() {
          _selectedRegion = null;
          _applyFilters();
        });
      },
      deleteIcon: const Icon(Icons.close, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTypeChip() {
    return Chip(
      avatar: Icon(
        _selectedType == EpaperType.zeitung ? Icons.newspaper : Icons.local_offer,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(_selectedType!.displayName),
      onDeleted: () {
        setState(() {
          _selectedType = null;
          _applyFilters();
        });
      },
      deleteIcon: const Icon(Icons.close, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _handleFilterMenuSelection(String value) {
    setState(() {
      if (value.startsWith('date_')) {
        final now = DateTime.now();
        switch (value) {
          case 'date_today':
            _startDate = DateTime(now.year, now.month, now.day);
            _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
            break;
          case 'date_week':
            _startDate = now.subtract(const Duration(days: 7));
            _endDate = now;
            break;
          case 'date_month':
            _startDate = now.subtract(const Duration(days: 30));
            _endDate = now;
            break;
          case 'date_all':
            _startDate = null;
            _endDate = null;
            break;
        }
      } else if (value.startsWith('region_')) {
        final region = value.substring(7);
        _selectedRegion = _selectedRegion == region ? null : region;
      } else if (value.startsWith('type_')) {
        final typeName = value.substring(5);
        final type = EpaperType.values.firstWhere((t) => t.name == typeName);
        _selectedType = _selectedType == type ? null : type;
      } else if (value == 'reset') {
        _resetFilters();
        return; // Don't call _applyFilters again
      }
      _applyFilters();
    });
  }

  Widget _buildActiveFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Aktive Filter:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${_filteredPdfAssets.length} von ${_pdfAssets.length} Dokumenten',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Date range chip
              if (_hasCustomDateRange()) _buildDateRangeChip(),
              // Region chip
              if (_selectedRegion != null) _buildRegionChip(),
              // Type chip
              if (_selectedType != null) _buildTypeChip(),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasCustomDateRange() {
    if (_startDate == null || _endDate == null) return true;
    
    final now = DateTime.now();
    final defaultStart = now.subtract(const Duration(days: 7));
    final defaultEnd = now;
    
    return !(_startDate!.isAtSameMomentAs(defaultStart) && 
             _endDate!.isAtSameMomentAs(defaultEnd));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('E-Paper PDF Betrachter'),
        actions: [
          // Filter menu button
          PopupMenuButton<String>(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_getActiveFilterCount()}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Dokumente filtern',
            onSelected: _handleFilterMenuSelection,
            itemBuilder: (context) => [
              // Date range options
              const PopupMenuItem<String>(
                value: 'date_today',
                child: ListTile(
                  leading: Icon(Icons.today),
                  title: Text('Heute'),
                  dense: true,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'date_week',
                child: ListTile(
                  leading: Icon(Icons.date_range),
                  title: Text('Letzte Woche'),
                  dense: true,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'date_month',
                child: ListTile(
                  leading: Icon(Icons.calendar_month),
                  title: Text('Letzter Monat'),
                  dense: true,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'date_all',
                child: ListTile(
                  leading: Icon(Icons.all_inclusive),
                  title: Text('Alle Zeiten'),
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              // Region options
              ..._getAvailableRegions().map((region) => PopupMenuItem<String>(
                value: 'region_$region',
                child: ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text(region),
                  trailing: _selectedRegion == region ? const Icon(Icons.check) : null,
                  dense: true,
                ),
              )),
              const PopupMenuDivider(),
              // Type options
              ..._getAvailableTypes().map((type) => PopupMenuItem<String>(
                value: 'type_${type.name}',
                child: ListTile(
                  leading: Icon(type == EpaperType.zeitung ? Icons.newspaper : Icons.local_offer),
                  title: Text(type.displayName),
                  trailing: _selectedType == type ? const Icon(Icons.check) : null,
                  dense: true,
                ),
              )),
              if (_hasActiveFilters()) ...[
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'reset',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Filter zurücksetzen'),
                    dense: true,
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPdfAssets,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chips (always visible when filters are active)
          if (_hasActiveFilters()) _buildActiveFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF-Dokumente werden geladen...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Fehler',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPdfAssets,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_pdfAssets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Keine PDF-Dokumente verfügbar',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredPdfAssets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Dokumente entsprechen den aktuellen Filtern',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_pdfAssets.length} Dokumente verfügbar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetFilters,
              child: const Text('Filter zurücksetzen'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive grid parameters
          final screenWidth = constraints.maxWidth;
          int crossAxisCount;
          double maxItemWidth;
          
          if (screenWidth > 1200) {
            // Large screens (desktop): 4 columns, max width 300px
            crossAxisCount = 4;
            maxItemWidth = 300.0;
          } else if (screenWidth > 800) {
            // Medium screens (tablet landscape): 3 columns, max width 350px
            crossAxisCount = 3;
            maxItemWidth = 350.0;
          } else if (screenWidth > 600) {
            // Small tablets: 2 columns, max width 400px
            crossAxisCount = 2;
            maxItemWidth = 400.0;
          } else {
            // Mobile: 2 columns, no max width restriction
            crossAxisCount = 2;
            maxItemWidth = double.infinity;
          }
          
          // Calculate actual item width and adjust cross axis count if needed
          double itemWidth = (screenWidth - (crossAxisCount + 1) * 8.0) / crossAxisCount;
          
          // If item width exceeds max width on large screens, increase column count
          if (maxItemWidth != double.infinity && itemWidth > maxItemWidth) {
            crossAxisCount = ((screenWidth - 8.0) / (maxItemWidth + 8.0)).floor();
            crossAxisCount = crossAxisCount.clamp(2, 6); // Ensure reasonable bounds
          }
          
          return RefreshIndicator(
            onRefresh: _loadPdfAssets,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: _filteredPdfAssets.length,
              itemBuilder: (context, index) {
                final pdfAsset = _filteredPdfAssets[index];
                
                return PdfThumbnailCard(
                  pdfAsset: pdfAsset,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(pdfAsset: pdfAsset),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Date Range Filter
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  _startDate = date;
                                  _applyFilters();
                                });
                              }
                            },
                            child: Text(
                              _startDate != null 
                                ? '${_startDate!.day}.${_startDate!.month}.${_startDate!.year}'
                                : 'Start Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('to'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  _endDate = date;
                                  _applyFilters();
                                });
                              }
                            },
                            child: Text(
                              _endDate != null 
                                ? '${_endDate!.day}.${_endDate!.month}.${_endDate!.year}'
                                : 'End Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _clearDateFilter,
                          icon: const Icon(Icons.clear, size: 16),
                          tooltip: 'Clear date filter',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Region and Type Filters
          Row(
            children: [
              // Region Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Region',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      hint: const Text('All Regions'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Regions'),
                        ),
                        ..._getAvailableRegions().map((region) => DropdownMenuItem<String>(
                          value: region,
                          child: Text(region),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRegion = value;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Type Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<EpaperType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      hint: const Text('All Types'),
                      items: [
                        const DropdownMenuItem<EpaperType>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ..._getAvailableTypes().map((type) => DropdownMenuItem<EpaperType>(
                          value: type,
                          child: Text(type.displayName),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Filter Summary
          if (_filteredPdfAssets.length != _pdfAssets.length)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Showing ${_filteredPdfAssets.length} of ${_pdfAssets.length} documents',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Note: Don't dispose the singleton PdfService here
    super.dispose();
  }
}

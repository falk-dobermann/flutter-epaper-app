import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdfrx/pdfrx.dart';

import '../config/app_theme.dart';
import '../models/epaper_metadata.dart';
import '../models/pdf_asset.dart';
import '../services/pdf_service.dart';
import '../widgets/pdf_outline_panel.dart';
import '../widgets/pdf_thumbnail_panel.dart';

class PdfViewerScreen extends StatefulWidget {
  final PdfAsset pdfAsset;

  const PdfViewerScreen({super.key, required this.pdfAsset});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with TickerProviderStateMixin {
  late PdfViewerController controller;
  late AnimationController _toolbarAnimationController;
  late Animation<double> _toolbarAnimation;
  bool showThumbnails = false;
  bool showOutline = false;
  bool _isToolbarVisible = true;
  int currentPage = 1;
  int totalPages = 0;
  double zoomLevel = 1.0;
  double _fitToScreenScale = 1.0;
  static const double minZoom = 0.5;
  static const double maxZoom = 5.0;
  Uint8List? pdfData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = PdfViewerController();
    controller.addListener(_onPageChanged);
    controller.addListener(_onZoomChanged);
    
    // Initialize animation controller for toolbar visibility
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toolbarAnimation = CurvedAnimation(
      parent: _toolbarAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Start with toolbar visible
    _toolbarAnimationController.forward();
    
    // Initialize German locale for date formatting
    _initializeDateFormatting();
    
    _loadPdfDocument();
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('de_DE', null);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize German locale, using default: $e');
      }
    }
  }

  // Custom layout function for horizontal page ordering
  static PdfPageLayout _layoutPagesHorizontally(List<PdfPage> pages, PdfViewerParams params) {
    final height = pages.fold(0.0, (prev, page) => max(prev, page.height)) + params.margin * 2;
    final pageLayouts = <Rect>[];
    double x = params.margin;
    for (final page in pages) {
      pageLayouts.add(
        Rect.fromLTWH(
          x,
          (height - page.height) / 2, // center vertically
          page.width,
          page.height,
        ),
      );
      x += page.width + params.margin;
    }
    return PdfPageLayout(pageLayouts: pageLayouts, documentSize: Size(x, height));
  }

  @override
  Widget build(BuildContext context) {
    // Calculate toolbar heights for proper positioning
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final pageCounterHeight = 56.0;
    final toolbarTotalHeight = _isToolbarVisible 
        ? appBarHeight + statusBarHeight + pageCounterHeight 
        : 0.0;

    return Scaffold(
      body: Stack(
        children: [
          // Main PDF viewer - positioned to avoid toolbar overlap
          Positioned(
            top: toolbarTotalHeight,
            left: (showThumbnails || showOutline) && _isToolbarVisible ? 250.0 : 0.0,
            right: 0,
            bottom: 0,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : pdfData == null
                    ? const Center(child: Text('Failed to load PDF'))
                    : Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            try {
                              _handleMouseWheelZoom(pointerSignal);
                            } catch (e) {
                              // Silently handle Flutter 3.32.0 trackpad assertion bug
                              // This allows trackpad scrolling to continue working
                              if (kDebugMode) {
                                debugPrint('Pointer event handled with fallback: $e');
                              }
                            }
                          }
                        },
                        child: GestureDetector(
                          onDoubleTap: _handleDoubleTapZoom,
                          onTap: _toggleToolbarVisibility,
                          child: PdfViewer.data(
                            pdfData!,
                            sourceName: widget.pdfAsset.id,
                            controller: controller,
                            params: PdfViewerParams(
                              layoutPages: _layoutPagesHorizontally,
                              minScale: minZoom,
                              maxScale: maxZoom,
                              boundaryMargin: EdgeInsets.all(_isToolbarVisible ? 80.0 : 20.0),
                              panEnabled: true,
                              scaleEnabled: true,
                              textSelectionParams: const PdfTextSelectionParams(
                                enabled: false,
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
          
          // Animated AppBar - positioned at top, only visible when toolbar is visible
          if (_isToolbarVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_toolbarAnimation),
                child: AppBar(
                  title: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/siteLogo.svg',
                        height: 28,
                        colorFilter: ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.pdfAsset.epaperMetadata != null) ...[
                              // Show brand text only if it's not "Kölner Stadt-Anzeiger"
                              if (widget.pdfAsset.epaperMetadata!.brand != "Kölner Stadt-Anzeiger")
                                Text(
                                  widget.pdfAsset.epaperMetadata!.brand,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              // Date on top line - large format with weekday
                              Text(
                                _formatDateWithWeekday(widget.pdfAsset.epaperMetadata!.publishDate),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // Region and type badge on second line
                              Row(
                                children: [
                                  Text(
                                    widget.pdfAsset.epaperMetadata!.region,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                  // Show type badge only if brand is not "Kölner Stadt-Anzeiger"
                                  if (widget.pdfAsset.epaperMetadata!.brand != "Kölner Stadt-Anzeiger") ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: widget.pdfAsset.epaperMetadata!.type == EpaperType.zeitung
                                            ? AppTheme.brandColor.withValues(alpha: 0.3)
                                            : Colors.orange.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.pdfAsset.epaperMetadata!.typeDisplayName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ] else ...[
                              Text(
                                widget.pdfAsset.formattedTitle,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  actions: [
                    // Zoom controls
                    IconButton(
                      icon: const Icon(Icons.zoom_out),
                      onPressed: (zoomLevel > minZoom && _isControllerReady) ? _zoomOut : null,
                      disabledColor: Theme.of(context).appBarTheme.iconTheme?.color?.withValues(alpha: 0.6),
                      tooltip: 'Zoom Out',
                    ),
                    Text(
                      '${(zoomLevel * 100).round()}%',
                      style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                        color: _isControllerReady 
                            ? Theme.of(context).appBarTheme.iconTheme?.color 
                            : Theme.of(context).appBarTheme.iconTheme?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_in),
                      onPressed: (zoomLevel < maxZoom && _isControllerReady) ? _zoomIn : null,
                      disabledColor: Theme.of(context).appBarTheme.iconTheme?.color?.withValues(alpha: 0.6),
                      tooltip: 'Zoom In',
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out_map),
                      onPressed: _isControllerReady ? _resetZoom : null,
                      disabledColor: Theme.of(context).appBarTheme.iconTheme?.color?.withValues(alpha: 0.6),
                      tooltip: 'Reset Zoom',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(showThumbnails ? Icons.view_list : Icons.view_module),
                      onPressed: () {
                        setState(() {
                          showThumbnails = !showThumbnails;
                          showOutline = false;
                        });
                        // Recalculate fit-to-screen scale when panel visibility changes
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _calculateFitToScreenScale();
                        });
                      },
                      tooltip: 'Toggle Page Thumbnails',
                    ),
                    IconButton(
                      icon: Icon(showOutline ? Icons.list_alt : Icons.format_list_bulleted),
                      onPressed: () {
                        setState(() {
                          showOutline = !showOutline;
                          showThumbnails = false;
                        });
                        // Recalculate fit-to-screen scale when panel visibility changes
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _calculateFitToScreenScale();
                        });
                      },
                      tooltip: 'Toggle Table of Contents',
                    ),
                  ],
                ),
              ),
            ),
          
          // Animated Page counter - positioned below AppBar, only visible when toolbar is visible
          if (_isToolbarVisible)
            Positioned(
              top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_toolbarAnimation),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
                        icon: const Icon(Icons.navigate_before),
                      ),
                      Text(
                        'Page $currentPage of $totalPages',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        onPressed: currentPage < totalPages ? () => _goToPage(currentPage + 1) : null,
                        icon: const Icon(Icons.navigate_next),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Animated Side panel for thumbnails or outline
          if (showThumbnails || showOutline)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: Offset.zero,
                ).animate(_toolbarAnimation),
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: showThumbnails
                      ? PdfThumbnailPanel(
                          pdfAsset: widget.pdfAsset,
                          currentPage: currentPage,
                          totalPages: totalPages,
                          onPageTap: _goToPage,
                        )
                      : PdfOutlinePanel(
                          pdfAsset: widget.pdfAsset,
                          onPageTap: _goToPage,
                        ),
                ),
              ),
            ),
          
        ],
      ),
    );
  }

  Future<void> _loadPdfDocument() async {
    try {
      final pdfService = PdfService();
      final data = await pdfService.downloadPdf(widget.pdfAsset.id);
      final document = await PdfDocument.openData(data);
      
      setState(() {
        pdfData = data;
        totalPages = document.pages.length;
        isLoading = false;
      });
      
      // Calculate fit-to-screen scale after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateFitToScreenScale();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading PDF ${widget.pdfAsset.id}: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onPageChanged() {
    if (_isControllerReady) {
      setState(() {
        currentPage = controller.pageNumber ?? 1;
      });
    }
  }

  void _goToPage(int pageNumber) {
    if (_isControllerReady) {
      controller.goToPage(pageNumber: pageNumber);
    }
  }

  // Zoom functionality methods
  void _onZoomChanged() {
    // Update zoom level from controller if available
    if (_isControllerReady) {
      setState(() {
        // Get the actual zoom level from the controller
        // The controller.currentZoom gives us the actual zoom ratio from the transformation matrix
        final actualZoom = controller.currentZoom;
        // Convert from actual scale to our zoom level (relative to fit-to-screen scale)
        zoomLevel = actualZoom / _fitToScreenScale;
      });
    }
  }

  void _zoomIn() {
    final double newZoom = (zoomLevel * 1.2).clamp(minZoom, maxZoom);
    _setZoom(newZoom);
  }

  void _zoomOut() {
    final double newZoom = (zoomLevel / 1.2).clamp(minZoom, maxZoom);
    _setZoom(newZoom);
  }

  void _resetZoom() {
    _setZoom(1.0);
  }

  void _setZoom(double zoom) {
    setState(() {
      zoomLevel = zoom;
    });
    // Use the pdfrx controller's zoom functionality
    // Only set zoom if controller is ready and has a valid state
    if (_isControllerReady) {
      try {
        // Calculate the actual scale factor: zoom level 1.0 = fit to screen
        final double actualScale = _fitToScreenScale * zoom;
        controller.setZoom(_centerPosition, actualScale);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error setting zoom: $e');
        }
        // Fallback: just update the zoom level in state
      }
    }
  }

  bool get _isControllerReady {
    try {
      // Check if controller has a valid state by accessing a property
      // Also ensure we have PDF data loaded
      return pdfData != null && !isLoading;
    } catch (e) {
      return false;
    }
  }

  Offset get _centerPosition {
    if (_isControllerReady) {
      try {
        return controller.centerPosition;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error getting center position: $e');
        }
        // Return a default center position
        return const Offset(0.5, 0.5);
      }
    }
    return const Offset(0.5, 0.5);
  }

  void _handleMouseWheelZoom(PointerScrollEvent event) {
    // Check if Ctrl key is pressed for zoom (common desktop pattern)
    if (_isControllerReady &&
        (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
         HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight))) {
      
      final double zoomDelta = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      final double newZoom = (zoomLevel * zoomDelta).clamp(minZoom, maxZoom);
      _setZoom(newZoom);
    }
  }

  void _handleDoubleTapZoom() {
    if (kDebugMode) {
      debugPrint('Double tap detected, current zoom: $zoomLevel');
    }
    if (!_isControllerReady) return;
    
    // Double-tap to zoom in, or reset to fit if already zoomed in
    if (zoomLevel < 1.0) {
      // If at normal zoom or less, zoom in to 2x
      _setZoom(1.0);
    } else if (zoomLevel < 3.0) {
      // If between 1x and 3x, zoom to 3x
      _setZoom(zoomLevel + 0.5); // Zoom in further
    } else {
      // If already zoomed in significantly, reset to fit
      _setZoom(1.0);
    }
  }

  void _toggleToolbarVisibility() {
    setState(() {
      _isToolbarVisible = !_isToolbarVisible;
    });
    
    if (_isToolbarVisible) {
      _toolbarAnimationController.forward();
    } else {
      _toolbarAnimationController.reverse();
    }
    
    // Recalculate fit-to-screen scale when toolbar visibility changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateFitToScreenScale();
    });
  }

  void _calculateFitToScreenScale() async {
    if (!_isControllerReady || pdfData == null) return;
    
    try {
      // Load the PDF document to get page dimensions
      final document = await PdfDocument.openData(pdfData!);
      if (document.pages.isEmpty) return;
      
      // Get the first page to calculate dimensions
      final firstPage = document.pages.first;
      
      // Check if widget is still mounted before using context
      if (!mounted) return;
      
      // Get the available screen size
      final screenSize = MediaQuery.of(context).size;
      double availableHeight = screenSize.height;
      double availableWidth = screenSize.width;
      
      // Adjust for toolbar visibility
      if (_isToolbarVisible) {
        final appBarHeight = AppBar().preferredSize.height;
        final pageCounterHeight = 56.0; // Approximate height of page counter
        availableHeight -= appBarHeight + pageCounterHeight + MediaQuery.of(context).padding.top;
        
        // Calculate available width (excluding side panel if visible)
        if (showThumbnails || showOutline) {
          availableWidth -= 250; // Side panel width
        }
      }
      
      // Account for margins (smaller margins in fullscreen mode)
      final margin = _isToolbarVisible ? 80.0 : 20.0;
      availableWidth -= margin * 2;
      availableHeight -= margin * 2;
      
      // Calculate scale factors for width and height
      final scaleX = availableWidth / firstPage.width;
      final scaleY = availableHeight / firstPage.height;
      
      // Use the smaller scale to ensure the page fits completely
      final newFitToScreenScale = min(scaleX, scaleY);
      
      setState(() {
        _fitToScreenScale = newFitToScreenScale;
      });
      
      // Only apply initial zoom if this is the first time (when loading PDF)
      // Don't reset zoom when recalculating due to panel changes
      if (zoomLevel == 1.0) {
        _setZoom(1.0);
      } else {
        // Reapply current zoom level with new scale
        _setZoom(zoomLevel);
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating fit-to-screen scale: $e');
      }
      // Fallback to default scale
      setState(() {
        _fitToScreenScale = 1.0;
      });
    }
  }

  String _formatDateWithWeekday(DateTime date) {
    try {
      final formatter = DateFormat('EEEE, d. MMMM yyyy', 'de_DE');
      return formatter.format(date);
    } catch (e) {
      // Fallback to English format if German locale fails
      if (kDebugMode) {
        debugPrint('German date formatting failed, using fallback: $e');
      }
      try {
        final fallbackFormatter = DateFormat('EEEE, MMMM d, yyyy');
        return fallbackFormatter.format(date);
      } catch (e2) {
        // Ultimate fallback to simple format
        if (kDebugMode) {
          debugPrint('All date formatting failed, using simple format: $e2');
        }
        return '${date.day}.${date.month}.${date.year}';
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onPageChanged);
    controller.removeListener(_onZoomChanged);
    _toolbarAnimationController.dispose();
    super.dispose();
  }
}

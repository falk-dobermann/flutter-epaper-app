import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/pdf_asset.dart';
import '../services/pdf_service.dart';
import '../widgets/pdf_thumbnail_panel.dart';
import '../widgets/pdf_outline_panel.dart';

class PdfViewerScreen extends StatefulWidget {
  final PdfAsset pdfAsset;

  const PdfViewerScreen({super.key, required this.pdfAsset});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController controller;
  bool showThumbnails = false;
  bool showOutline = false;
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
    _loadPdfDocument();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfAsset.formattedTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: (zoomLevel > minZoom && _isControllerReady) ? _zoomOut : null,
            tooltip: 'Zoom Out',
          ),
          Text(
            '${(zoomLevel * 100).round()}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: (zoomLevel < maxZoom && _isControllerReady) ? _zoomIn : null,
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _isControllerReady ? _resetZoom : null,
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
      body: Column(
        children: [
          // Page counter
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).colorScheme.surfaceVariant,
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
          Expanded(
            child: Row(
              children: [
                // Side panel for thumbnails or outline
                if (showThumbnails || showOutline)
                  Container(
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
                // Main PDF viewer with zoom support
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : pdfData == null
                          ? const Center(child: Text('Failed to load PDF'))
                          : Listener(
                              onPointerSignal: (pointerSignal) {
                                if (pointerSignal is PointerScrollEvent) {
                                  _handleMouseWheelZoom(pointerSignal);
                                }
                              },
                              child: GestureDetector(
                                onDoubleTap: _handleDoubleTapZoom,
                                onTap: _handleSingleTap,
                                child: PdfViewer.data(
                                  pdfData!,
                                  sourceName: widget.pdfAsset.id,
                                  controller: controller,
                                  params: PdfViewerParams(
                                    layoutPages: _layoutPagesHorizontally,
                                    minScale: minZoom,
                                    maxScale: maxZoom,
                                    boundaryMargin: const EdgeInsets.all(80.0),
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
              ],
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
      print('Error loading PDF ${widget.pdfAsset.id}: $e');
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
        print('Error setting zoom: $e');
        // Fallback: just update the zoom level in state
      }
    }
  }

  bool get _isControllerReady {
    try {
      // Check if controller has a valid state by accessing a property
      // Also ensure we have PDF data loaded
      return controller.value != null && pdfData != null && !isLoading;
    } catch (e) {
      return false;
    }
  }

  Offset get _centerPosition {
    if (_isControllerReady) {
      try {
        return controller.centerPosition;
      } catch (e) {
        print('Error getting center position: $e');
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
    print('Double tap detected, current zoom: $zoomLevel');
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

  void _handleSingleTap() {
    // Single tap can be used for other interactions if needed
    // For now, we'll just ensure focus is on the viewer
    // This helps with keyboard navigation
  }

  void _calculateFitToScreenScale() async {
    if (!_isControllerReady || pdfData == null) return;
    
    try {
      // Load the PDF document to get page dimensions
      final document = await PdfDocument.openData(pdfData!);
      if (document.pages.isEmpty) return;
      
      // Get the first page to calculate dimensions
      final firstPage = document.pages.first;
      
      // Get the available screen size (excluding app bar and page counter)
      final screenSize = MediaQuery.of(context).size;
      final appBarHeight = AppBar().preferredSize.height;
      final pageCounterHeight = 56.0; // Approximate height of page counter
      double availableHeight = screenSize.height - appBarHeight - pageCounterHeight - MediaQuery.of(context).padding.top;
      
      // Calculate available width (excluding side panel if visible)
      double availableWidth = screenSize.width;
      if (showThumbnails || showOutline) {
        availableWidth -= 250; // Side panel width
      }
      
      // Account for margins
      const margin = 80.0; // From boundaryMargin in PdfViewerParams
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
      print('Error calculating fit-to-screen scale: $e');
      // Fallback to default scale
      setState(() {
        _fitToScreenScale = 1.0;
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onPageChanged);
    controller.removeListener(_onZoomChanged);
    super.dispose();
  }
}

import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/pdf_asset.dart';
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
  static const double minZoom = 0.5;
  static const double maxZoom = 5.0;

  @override
  void initState() {
    super.initState();
    controller = PdfViewerController();
    controller.addListener(_onPageChanged);
    controller.addListener(_onZoomChanged);
    _loadTotalPages();
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
            onPressed: zoomLevel > minZoom ? _zoomOut : null,
            tooltip: 'Zoom Out',
          ),
          Text(
            '${(zoomLevel * 100).round()}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: zoomLevel < maxZoom ? _zoomIn : null,
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _resetZoom,
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
                  child: Listener(
                    onPointerSignal: (pointerSignal) {
                      if (pointerSignal is PointerScrollEvent) {
                        _handleMouseWheelZoom(pointerSignal);
                      }
                    },
                    child: GestureDetector(
                      onDoubleTap: _handleDoubleTapZoom,
                      onTap: _handleSingleTap,
                      child: PdfViewer.asset(
                        widget.pdfAsset.path,
                        controller: controller,
                        params: PdfViewerParams(
                          layoutPages: _layoutPagesHorizontally,
                          minScale: minZoom,
                          maxScale: maxZoom,
                          boundaryMargin: const EdgeInsets.all(80.0),
                          panEnabled: true,
                          scaleEnabled: true,
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

  Future<PdfDocument?> _loadPdfDocument() async {
    try {
      final bytes = await rootBundle.load(widget.pdfAsset.path);
      return await PdfDocument.openData(bytes.buffer.asUint8List());
    } catch (e) {
      print('Error loading PDF ${widget.pdfAsset.path}: $e');
      return null;
    }
  }

  void _loadTotalPages() async {
    try {
      final document = await _loadPdfDocument();
      if (document != null) {
        setState(() {
          totalPages = document.pages.length;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _onPageChanged() {
    setState(() {
      currentPage = controller.pageNumber ?? 1;
    });
  }

  void _goToPage(int pageNumber) {
    controller.goToPage(pageNumber: pageNumber);
  }

  // Zoom functionality methods
  void _onZoomChanged() {
    // Update zoom level from controller if available
    setState(() {
      // For now, we'll track zoom level manually since pdfrx doesn't expose current zoom
      // The zoom level will be updated in the zoom methods
    });
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
    controller.setZoom(_centerPosition, zoom);
  }

  Offset get _centerPosition => controller.centerPosition;

  void _handleMouseWheelZoom(PointerScrollEvent event) {
    // Check if Ctrl key is pressed for zoom (common desktop pattern)
    if (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight)) {
      
      final double zoomDelta = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      final double newZoom = (zoomLevel * zoomDelta).clamp(minZoom, maxZoom);
      _setZoom(newZoom);
    }
  }

  void _handleDoubleTapZoom() {
    // Double-tap to zoom in, or reset to fit if already zoomed in
    if (zoomLevel <= 1.0) {
      // If at normal zoom or less, zoom in to 2x
      _setZoom(2.0);
    } else if (zoomLevel < 3.0) {
      // If between 1x and 3x, zoom to 3x
      _setZoom(3.0);
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

  @override
  void dispose() {
    controller.removeListener(_onPageChanged);
    controller.removeListener(_onZoomChanged);
    super.dispose();
  }
}

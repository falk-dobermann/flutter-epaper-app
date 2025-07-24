import 'dart:math';
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

  @override
  void initState() {
    super.initState();
    controller = PdfViewerController();
    controller.addListener(_onPageChanged);
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
                // Main PDF viewer
                Expanded(
                  child: PdfViewer.asset(
                    widget.pdfAsset.path,
                    controller: controller,
                    params: const PdfViewerParams(
                      layoutPages: _layoutPagesHorizontally,
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

  @override
  void dispose() {
    controller.removeListener(_onPageChanged);
    super.dispose();
  }
}

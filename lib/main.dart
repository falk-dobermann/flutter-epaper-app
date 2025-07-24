import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize pdfrx with platform-specific method
  try {
    if (kIsWeb) {
      // Use Flutter-specific initialization for web
      pdfrxFlutterInitialize();
    } else {
      // Use standard initialization for mobile/desktop
      await pdfrxInitialize();
    }
  } catch (e) {
    // Initialization might fail on some platforms, continue anyway
    print('pdfrx initialization: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Paper PDF Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PdfListScreen(),
    );
  }
}

class PdfListScreen extends StatelessWidget {
  const PdfListScreen({super.key});

  final List<String> pdfAssets = const [
    'assets/pdf/cologne.pdf',
    'assets/pdf/23-07-2025-Koeln-Rechtsrheinisch.pdf',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('E-Paper PDF Viewer'),
      ),
      body: Padding(
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
            
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: pdfAssets.length,
              itemBuilder: (context, index) {
                final pdfPath = pdfAssets[index];
                final fileName = pdfPath.split('/').last;
                
                return PdfThumbnailCard(
                  pdfPath: pdfPath,
                  fileName: fileName,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(pdfPath: pdfPath),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PdfThumbnailCard extends StatefulWidget {
  final String pdfPath;
  final String fileName;
  final VoidCallback onTap;

  const PdfThumbnailCard({
    super.key,
    required this.pdfPath,
    required this.fileName,
    required this.onTap,
  });

  @override
  State<PdfThumbnailCard> createState() => _PdfThumbnailCardState();
}

class _PdfThumbnailCardState extends State<PdfThumbnailCard> with SingleTickerProviderStateMixin {
  PdfDocument? _document;
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadPdfDocument();
  }

  Future<void> _loadPdfDocument() async {
    try {
      final bytes = await rootBundle.load(widget.pdfPath);
      final document = await PdfDocument.openData(bytes.buffer.asUint8List());
      if (mounted) {
        setState(() {
          _document = document;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading PDF ${widget.pdfPath}: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatFileName(String fileName) {
    // Remove .pdf extension and format the name
    String name = fileName.replaceAll('.pdf', '');
    // Replace hyphens and underscores with spaces
    name = name.replaceAll(RegExp(r'[-_]'), ' ');
    // Capitalize first letter of each word
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.grey[50]!,
                              Colors.grey[100]!,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            _buildThumbnail(),
                            // Subtle overlay for better text readability
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PDF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatFileName(widget.fileName),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _document != null 
                                      ? '${_document!.pages.length} pages'
                                      : _isLoading 
                                          ? 'Loading...'
                                          : 'Error loading',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              if (_document != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Ready',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail() {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: 8),
              Text(
                'Loading PDF...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _document == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load PDF',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PdfPageView(
            document: _document!,
            pageNumber: 1,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _document?.dispose();
    super.dispose();
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;

  const PdfViewerScreen({super.key, required this.pdfPath});

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
        title: Text(widget.pdfPath.split('/').last),
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
                        ? _buildThumbnailPanel()
                        : _buildOutlinePanel(),
                  ),
                // Main PDF viewer
                Expanded(
                  child: PdfViewer.asset(
                    widget.pdfPath,
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

  Widget _buildThumbnailPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Page Thumbnails',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: totalPages,
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              return Card(
                margin: const EdgeInsets.all(4.0),
                child: InkWell(
                  onTap: () => _goToPage(pageNumber),
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Actual PDF page thumbnail
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: currentPage == pageNumber 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Colors.grey,
                              width: currentPage == pageNumber ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FutureBuilder<PdfDocument?>(
                            future: _loadPdfDocument(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting ||
                                  !snapshot.hasData) {
                                return Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$pageNumber',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.white,
                                      child: PdfPageView(
                                        document: snapshot.data!,
                                        pageNumber: pageNumber,
                                        alignment: Alignment.center,
                                      ),
                                    ),
                                  ),
                                  if (currentPage == pageNumber)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Current',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Page $pageNumber',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              if (currentPage == pageNumber)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Current',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOutlinePanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Table of Contents',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: FutureBuilder<PdfDocument?>(
            future: _loadPdfDocument(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Text('No table of contents available'),
                );
              }

              final document = snapshot.data!;
              return FutureBuilder<List<PdfOutlineNode>>(
                future: document.loadOutline(),
                builder: (context, outlineSnapshot) {
                  if (outlineSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (outlineSnapshot.hasError || !outlineSnapshot.hasData || outlineSnapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'This PDF does not contain a table of contents',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView(
                    children: outlineSnapshot.data!
                        .map((node) => _buildOutlineItem(node, 0))
                        .toList(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOutlineItem(PdfOutlineNode node, int level) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 + (level * 20.0), right: 16.0),
          title: Text(
            node.title,
            style: TextStyle(
              fontSize: 14 - (level * 1.0),
              fontWeight: level == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () {
            if (node.dest?.pageNumber != null) {
              _goToPage(node.dest!.pageNumber!);
            }
          },
          trailing: node.dest?.pageNumber != null
              ? Text(
                  'p.${node.dest!.pageNumber}',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
        ),
        ...node.children.map((child) => _buildOutlineItem(child, level + 1)),
      ],
    );
  }

  Future<PdfDocument?> _loadPdfDocument() async {
    try {
      final bytes = await rootBundle.load(widget.pdfPath);
      return await PdfDocument.openData(bytes.buffer.asUint8List());
    } catch (e) {
      print('Error loading PDF ${widget.pdfPath}: $e');
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

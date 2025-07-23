import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
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
    'assets/pdf/23-07-2025-Köln Rechtsrheinisch.pdf',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('E-Paper PDF Viewer'),
      ),
      body: ListView.builder(
        itemCount: pdfAssets.length,
        itemBuilder: (context, index) {
          final pdfPath = pdfAssets[index];
          final fileName = pdfPath.split('/').last;
          
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(fileName),
              subtitle: Text(pdfPath),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(pdfPath: pdfPath),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
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
                        // Thumbnail placeholder
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              '$pageNumber',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
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

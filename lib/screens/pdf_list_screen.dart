import 'package:flutter/material.dart';

import '../widgets/pdf_thumbnail_card.dart';
import '../models/pdf_asset.dart';
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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load PDF list: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('E-Paper PDF Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPdfAssets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
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
            Text('Loading PDF documents...'),
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
              'Error',
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
              child: const Text('Retry'),
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
              'No PDF documents available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
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
              itemCount: _pdfAssets.length,
              itemBuilder: (context, index) {
                final pdfAsset = _pdfAssets[index];
                
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

  @override
  void dispose() {
    // Note: Don't dispose the singleton PdfService here
    super.dispose();
  }
}

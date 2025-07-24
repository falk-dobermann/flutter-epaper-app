import 'package:flutter/material.dart';

import '../widgets/pdf_thumbnail_card.dart';
import '../models/pdf_asset.dart';
import 'pdf_viewer_screen.dart';

class PdfListScreen extends StatelessWidget {
  const PdfListScreen({super.key});

  final List<PdfAsset> pdfAssets = const [
    PdfAsset(
      path: 'assets/pdf/cologne.pdf',
      title: 'Cologne',
    ),
    PdfAsset(
      path: 'assets/pdf/23-07-2025-Koeln-Rechtsrheinisch.pdf',
      title: '23-07-2025 Köln Rechtsrheinisch',
    ),
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
                final pdfAsset = pdfAssets[index];
                
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
            );
          },
        ),
      ),
    );
  }
}

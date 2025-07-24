import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/pdf_asset.dart';

class PdfThumbnailPanel extends StatelessWidget {
  final PdfAsset pdfAsset;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageTap;

  const PdfThumbnailPanel({
    super.key,
    required this.pdfAsset,
    required this.currentPage,
    required this.totalPages,
    required this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  onTap: () => onPageTap(pageNumber),
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

  Future<PdfDocument?> _loadPdfDocument() async {
    try {
      // For now, return null since we're using API-based loading
      // Thumbnails will be handled differently in the API approach
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading PDF ${pdfAsset.id}: $e');
      }
      return null;
    }
  }
}

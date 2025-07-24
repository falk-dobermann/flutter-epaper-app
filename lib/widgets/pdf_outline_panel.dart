import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/pdf_asset.dart';

class PdfOutlinePanel extends StatelessWidget {
  final PdfAsset pdfAsset;
  final Function(int) onPageTap;

  const PdfOutlinePanel({
    super.key,
    required this.pdfAsset,
    required this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
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
                        .map((node) => _buildOutlineItem(context, node, 0))
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

  Widget _buildOutlineItem(BuildContext context, PdfOutlineNode node, int level) {
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
              onPageTap(node.dest!.pageNumber!);
            }
          },
          trailing: node.dest?.pageNumber != null
              ? Text(
                  'p.${node.dest!.pageNumber}',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
        ),
        ...node.children.map((child) => _buildOutlineItem(context, child, level + 1)),
      ],
    );
  }

  Future<PdfDocument?> _loadPdfDocument() async {
    try {
      final bytes = await rootBundle.load(pdfAsset.path);
      return await PdfDocument.openData(bytes.buffer.asUint8List());
    } catch (e) {
      print('Error loading PDF ${pdfAsset.path}: $e');
      return null;
    }
  }
}

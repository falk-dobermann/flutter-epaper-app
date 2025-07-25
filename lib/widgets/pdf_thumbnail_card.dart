import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../config/app_theme.dart';
import '../config/environment.dart';
import '../models/epaper_metadata.dart';
import '../models/pdf_asset.dart';

class PdfThumbnailCard extends StatefulWidget {
  final PdfAsset pdfAsset;
  final VoidCallback onTap;

  const PdfThumbnailCard({
    super.key,
    required this.pdfAsset,
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
      // For thumbnails, we don't need to load the full PDF
      // The server will generate thumbnails for us
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading PDF ${widget.pdfAsset.id}: $e');
      }
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                                  color: Colors.black.withValues(alpha: 0.7),
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
                          // Title and brand
                          if (widget.pdfAsset.epaperMetadata != null) ...[
                            Text(
                              widget.pdfAsset.epaperMetadata!.brand,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            widget.pdfAsset.epaperMetadata?.region ?? widget.pdfAsset.formattedTitle,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Metadata row
                          Row(
                            children: [
                              if (widget.pdfAsset.epaperMetadata != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.pdfAsset.epaperMetadata!.type == EpaperType.zeitung
                                        ? AppTheme.brandColor.withValues(alpha: 0.1)
                                        : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.pdfAsset.epaperMetadata!.typeDisplayName,
                                    style: TextStyle(
                                      color: widget.pdfAsset.epaperMetadata!.type == EpaperType.zeitung
                                          ? AppTheme.brandColor
                                          : Colors.orange[700],
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.pdfAsset.epaperMetadata?.formattedDate ?? widget.pdfAsset.formattedDate,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _isLoading 
                                      ? 'Loading...'
                                      : _error != null
                                          ? 'Error loading'
                                          : '${widget.pdfAsset.pageCount} pages • ${widget.pdfAsset.formattedFileSize}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (!_isLoading && _error == null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                'Loading...',
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

    if (_error != null) {
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
                'Failed to load',
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

    // Show actual PDF thumbnail if document is loaded
    if (_document != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: PdfPageView(
            document: _document!,
            pageNumber: 1, // Show first page as thumbnail
            alignment: Alignment.center,
          ),
        ),
      );
    }

    // Show server-generated thumbnail
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Image.network(
          '${Environment.apiBaseUrl}/api/pdfs/${widget.pdfAsset.id}/thumbnail',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading thumbnail...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.pdfAsset.formattedTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.pdfAsset.formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

class PdfAsset {
  final String id;
  final String title;
  final String description;
  final DateTime publishDate;
  final String? thumbnailUrl;
  final int fileSize;
  final int pageCount;
  final List<String> tags;
  final String? downloadUrl;
  final Map<String, dynamic>? metadata;

  const PdfAsset({
    required this.id,
    required this.title,
    required this.description,
    required this.publishDate,
    this.thumbnailUrl,
    required this.fileSize,
    required this.pageCount,
    required this.tags,
    this.downloadUrl,
    this.metadata,
  });

  // Create PdfAsset from JSON (API response)
  factory PdfAsset.fromJson(Map<String, dynamic> json) {
    return PdfAsset(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      publishDate: DateTime.parse(json['publishDate'] as String),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileSize: json['fileSize'] as int,
      pageCount: json['pageCount'] as int,
      tags: List<String>.from(json['tags'] as List? ?? []),
      downloadUrl: json['downloadUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert PdfAsset to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'publishDate': publishDate.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'tags': tags,
      'downloadUrl': downloadUrl,
      'metadata': metadata,
    };
  }

  // Legacy support for asset-based loading (fallback)
  String get fileName => '$id.pdf';
  
  String get formattedTitle {
    return title.isNotEmpty ? title : _formatIdAsTitle();
  }

  String _formatIdAsTitle() {
    // Format ID as title if title is empty
    String name = id.replaceAll('.pdf', '');
    name = name.replaceAll(RegExp(r'[-_]'), ' ');
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Format file size for display
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Format publish date for display
  String get formattedDate {
    return '${publishDate.day}.${publishDate.month}.${publishDate.year}';
  }

  // Get formatted publish date with time
  String get formattedDateTime {
    return '$formattedDate ${publishDate.hour.toString().padLeft(2, '0')}:${publishDate.minute.toString().padLeft(2, '0')}';
  }

  // Check if PDF is recent (published within last 7 days)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(publishDate);
    return difference.inDays <= 7;
  }

  // Get display subtitle with date and size
  String get subtitle {
    return '$formattedDate • $formattedFileSize • $pageCount Seiten';
  }

  // Get tags as formatted string
  String get formattedTags {
    return tags.join(', ');
  }

  // Create a copy with updated fields
  PdfAsset copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? publishDate,
    String? thumbnailUrl,
    int? fileSize,
    int? pageCount,
    List<String>? tags,
    String? downloadUrl,
    Map<String, dynamic>? metadata,
  }) {
    return PdfAsset(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      publishDate: publishDate ?? this.publishDate,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      tags: tags ?? this.tags,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'PdfAsset(id: $id, title: $title, publishDate: $publishDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfAsset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PdfAsset {
  final String path;
  final String title;

  const PdfAsset({
    required this.path,
    required this.title,
  });

  String get fileName => path.split('/').last;
  
  String get formattedTitle {
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
}

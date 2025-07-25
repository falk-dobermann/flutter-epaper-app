import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/pdf_asset.dart';
import '../models/epaper_metadata.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  final http.Client _client = http.Client();
  final Map<String, Uint8List> _cache = {};

  /// Get list of available PDF documents
  Future<List<PdfAsset>> getPdfList() async {
    try {
      if (Environment.getConfigValue('enableMockData', false)) {
        return _getMockPdfList();
      }

      final response = await _client.get(
        Uri.parse(Environment.pdfEndpoint),
        headers: Environment.apiHeaders,
      ).timeout(Environment.connectTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => PdfAsset.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load PDF list: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogging && kDebugMode) {
        debugPrint('Error fetching PDF list: $e');
      }
      // Fallback to mock data in case of error
      return _getMockPdfList();
    }
  }

  /// Download PDF file data
  Future<Uint8List> downloadPdf(String pdfId) async {
    try {
      // Check cache first
      if (Environment.enableCaching && _cache.containsKey(pdfId)) {
        if (Environment.enableLogging && kDebugMode) {
          debugPrint('Loading PDF from cache: $pdfId');
        }
        return _cache[pdfId]!;
      }

      if (Environment.getConfigValue('enableMockData', false)) {
        return await _getMockPdfData(pdfId);
      }

      final response = await _client.get(
        Uri.parse('${Environment.pdfEndpoint}/$pdfId/download'),
        headers: {
          'Accept': 'application/pdf',
        },
      ).timeout(Environment.receiveTimeout);

      if (response.statusCode == 200) {
        final pdfData = response.bodyBytes;
        
        // Cache the PDF data
        if (Environment.enableCaching) {
          _cache[pdfId] = pdfData;
          _manageCacheSize();
        }

        if (Environment.enableLogging && kDebugMode) {
          debugPrint('Downloaded PDF: $pdfId (${pdfData.length} bytes)');
        }

        return pdfData;
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogging && kDebugMode) {
        debugPrint('Error downloading PDF $pdfId: $e');
      }
      // Fallback to mock data
      return await _getMockPdfData(pdfId);
    }
  }

  /// Get PDF metadata
  Future<Map<String, dynamic>> getPdfMetadata(String pdfId) async {
    try {
      if (Environment.getConfigValue('enableMockData', false)) {
        return _getMockPdfMetadata(pdfId);
      }

      final response = await _client.get(
        Uri.parse('${Environment.pdfEndpoint}/$pdfId/metadata'),
        headers: Environment.apiHeaders,
      ).timeout(Environment.connectTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load PDF metadata: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogging && kDebugMode) {
        debugPrint('Error fetching PDF metadata for $pdfId: $e');
      }
      return _getMockPdfMetadata(pdfId);
    }
  }

  /// Get epaper metadata for a PDF
  Future<EpaperMetadata?> getEpaperMetadata(String pdfId) async {
    try {
      if (Environment.getConfigValue('enableMockData', false)) {
        return _getMockEpaperMetadata(pdfId);
      }

      final response = await _client.get(
        Uri.parse('${Environment.pdfEndpoint}/$pdfId/epaper-metadata'),
        headers: Environment.apiHeaders,
      ).timeout(Environment.connectTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return EpaperMetadata.fromJson(jsonData);
      } else {
        if (Environment.enableLogging && kDebugMode) {
          debugPrint('No epaper metadata found for $pdfId: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (Environment.enableLogging && kDebugMode) {
        debugPrint('Error fetching epaper metadata for $pdfId: $e');
      }
      return _getMockEpaperMetadata(pdfId);
    }
  }

  /// Clear PDF cache
  void clearCache() {
    _cache.clear();
    if (Environment.enableLogging && kDebugMode) {
      debugPrint('PDF cache cleared');
    }
  }

  /// Get cache size in bytes
  int getCacheSize() {
    return _cache.values.fold(0, (sum, data) => sum + data.length);
  }

  /// Manage cache size to prevent memory issues
  void _manageCacheSize() {
    while (getCacheSize() > Environment.maxCacheSize && _cache.isNotEmpty) {
      // Remove oldest entry (simple FIFO strategy)
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
      if (Environment.enableLogging && kDebugMode) {
        debugPrint('Removed $firstKey from cache due to size limit');
      }
    }
  }

  /// Mock PDF list for development/fallback
  List<PdfAsset> _getMockPdfList() {
    return [
      PdfAsset(
        id: 'cologne-2025-07-23',
        title: 'Köln Rechtsrheinisch',
        description: 'E-Paper vom 23.07.2025',
        publishDate: DateTime(2025, 7, 23),
        thumbnailUrl: 'assets/images/cologne-thumb.png',
        fileSize: 2048576, // 2MB
        pageCount: 36,
        tags: ['Köln', 'Rechtsrheinisch', '2025'],
        epaperMetadata: EpaperMetadata(
          brand: 'Kölner Stadt-Anzeiger',
          publishDate: DateTime(2025, 7, 23),
          region: 'Köln Rechtsrheinisch',
          type: EpaperType.zeitung,
        ),
      ),
      PdfAsset(
        id: 'cologne-general',
        title: 'Köln Allgemein',
        description: 'Allgemeine Ausgabe Köln',
        publishDate: DateTime(2025, 7, 20),
        thumbnailUrl: 'assets/images/cologne-general-thumb.png',
        fileSize: 1843200, // 1.8MB
        pageCount: 36,
        tags: ['Köln', 'Allgemein', '2025'],
        epaperMetadata: EpaperMetadata(
          brand: 'Kölner Stadt-Anzeiger',
          publishDate: DateTime(2025, 7, 20),
          region: 'Köln Allgemein',
          type: EpaperType.zeitung,
        ),
      ),
    ];
  }

  /// Mock PDF data for development/fallback
  Future<Uint8List> _getMockPdfData(String pdfId) async {
    // In development, try to load from assets as fallback
    try {
      // This would need to be implemented with proper asset loading
      // For now, return empty data
      return Uint8List(0);
    } catch (e) {
      if (Environment.enableLogging && kDebugMode) {
        debugPrint('Could not load mock PDF data for $pdfId: $e');
      }
      return Uint8List(0);
    }
  }

  /// Mock PDF metadata for development/fallback
  Map<String, dynamic> _getMockPdfMetadata(String pdfId) {
    return {
      'id': pdfId,
      'title': 'Mock PDF Document',
      'author': 'E-Paper System',
      'creationDate': DateTime.now().toIso8601String(),
      'pageCount': 36,
      'fileSize': 2048576,
      'version': '1.0',
    };
  }

  /// Mock epaper metadata for development/fallback
  EpaperMetadata? _getMockEpaperMetadata(String pdfId) {
    switch (pdfId) {
      case 'cologne-2025-07-23':
        return EpaperMetadata(
          brand: 'Kölner Stadt-Anzeiger',
          publishDate: DateTime(2025, 7, 23),
          region: 'Köln Rechtsrheinisch',
          type: EpaperType.zeitung,
        );
      case 'cologne-general':
        return EpaperMetadata(
          brand: 'Kölner Stadt-Anzeiger',
          publishDate: DateTime(2025, 7, 20),
          region: 'Köln Allgemein',
          type: EpaperType.zeitung,
        );
      default:
        return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
    _cache.clear();
  }
}

class EpaperMetadata {
  final String brand;
  final DateTime publishDate;
  final String region;
  final EpaperType type;

  const EpaperMetadata({
    required this.brand,
    required this.publishDate,
    required this.region,
    required this.type,
  });

  factory EpaperMetadata.fromJson(Map<String, dynamic> json) {
    return EpaperMetadata(
      brand: json['brand'] as String,
      publishDate: DateTime.parse(json['publishDate'] as String),
      region: json['region'] as String,
      type: EpaperType.fromString(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'publishDate': publishDate.toIso8601String().split('T')[0], // Date only
      'region': region,
      'type': type.value,
    };
  }

  String get formattedDate {
    return '${publishDate.day}.${publishDate.month}.${publishDate.year}';
  }

  String get typeDisplayName {
    return type.displayName;
  }

  @override
  String toString() {
    return 'EpaperMetadata(brand: $brand, region: $region, type: ${type.value}, publishDate: $publishDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpaperMetadata &&
        other.brand == brand &&
        other.publishDate == publishDate &&
        other.region == region &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(brand, publishDate, region, type);
  }
}

enum EpaperType {
  zeitung('Zeitung'),
  beilage('Beilage');

  const EpaperType(this.value);

  final String value;

  String get displayName {
    switch (this) {
      case EpaperType.zeitung:
        return 'Zeitung';
      case EpaperType.beilage:
        return 'Beilage';
    }
  }

  static EpaperType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'zeitung':
        return EpaperType.zeitung;
      case 'beilage':
        return EpaperType.beilage;
      default:
        throw ArgumentError('Unknown epaper type: $value');
    }
  }
}

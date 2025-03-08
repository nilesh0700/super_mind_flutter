import 'package:hive/hive.dart';

part 'shared_content.g.dart';

@HiveType(typeId: 0)
class SharedContent {
  @HiveField(0)
  final String? text;
  
  @HiveField(1)
  final List<String>? imageUris;
  
  @HiveField(2)
  final DateTime timestamp;

  SharedContent({
    this.text, 
    this.imageUris,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasContent => text != null || (imageUris != null && imageUris!.isNotEmpty);

  @override
  String toString() {
    if (text != null && (imageUris == null || imageUris!.isEmpty)) {
      return 'Text: $text';
    } else if (text == null && imageUris != null && imageUris!.isNotEmpty) {
      return 'Images: ${imageUris!.length}';
    } else if (text != null && imageUris != null && imageUris!.isNotEmpty) {
      return 'Text and ${imageUris!.length} images';
    } else {
      return 'No content';
    }
  }
  
  // Create a copy with optional new values
  SharedContent copyWith({
    String? text,
    List<String>? imageUris,
    DateTime? timestamp,
  }) {
    return SharedContent(
      text: text ?? this.text,
      imageUris: imageUris ?? this.imageUris,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  // Convert to a Map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'imageUris': imageUris,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  // Create from a Map (JSON deserialization)
  factory SharedContent.fromJson(Map<String, dynamic> json) {
    return SharedContent(
      text: json['text'],
      imageUris: json['imageUris'] != null 
          ? List<String>.from(json['imageUris']) 
          : null,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : null,
    );
  }
} 
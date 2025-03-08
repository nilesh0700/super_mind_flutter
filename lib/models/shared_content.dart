class SharedContent {
  final String? text;
  final List<String>? imageUris;

  SharedContent({this.text, this.imageUris});

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
} 
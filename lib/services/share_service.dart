import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareService {
  static const MethodChannel _channel = MethodChannel('com.example.super_mind_flutter/share');
  static final ShareService _instance = ShareService._internal();

  factory ShareService() {
    return _instance;
  }

  ShareService._internal();

  Future<bool> hasSharedContent() async {
    try {
      final bool hasContent = await _channel.invokeMethod('hasSharedContent');
      return hasContent;
    } on PlatformException catch (e) {
      debugPrint('Error checking for shared content: ${e.message}');
      return false;
    }
  }

  Future<String?> getSharedText() async {
    try {
      final String? text = await _channel.invokeMethod('getSharedText');
      return text;
    } on PlatformException catch (e) {
      debugPrint('Error getting shared text: ${e.message}');
      return null;
    }
  }

  Future<List<String>?> getSharedImageUris() async {
    try {
      final List<dynamic>? uris = await _channel.invokeMethod('getSharedImageUris');
      if (uris != null) {
        return uris.map((uri) => uri.toString()).toList();
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('Error getting shared image URIs: ${e.message}');
      return null;
    }
  }
} 
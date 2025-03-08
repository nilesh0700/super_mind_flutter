import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/shared_content.dart';

class ShareService {
  static const MethodChannel _channel = MethodChannel('com.example.super_mind_flutter/share');
  static final ShareService _instance = ShareService._internal();

  factory ShareService() {
    return _instance;
  }

  ShareService._internal();

  Future<SharedContentResult> getInitialSharedContent() async {
    try {
      final String jsonResult = await _channel.invokeMethod('getInitialSharedContent');
      debugPrint('Received initial shared content: $jsonResult');
      
      final Map<String, dynamic> data = json.decode(jsonResult);
      final bool isOpenedFromShare = data['isOpenedFromShare'] ?? false;
      
      String? text;
      List<String>? imageUris;
      
      if (data.containsKey('text')) {
        text = data['text'];
      }
      
      if (data.containsKey('imageUris')) {
        final String urisJson = data['imageUris'];
        final List<dynamic> urisList = json.decode(urisJson);
        imageUris = urisList.map((uri) => uri.toString()).toList();
      }
      
      final content = SharedContent(text: text, imageUris: imageUris);
      return SharedContentResult(
        isOpenedFromShare: isOpenedFromShare,
        content: content,
      );
    } on PlatformException catch (e) {
      debugPrint('Error getting initial shared content: ${e.message}');
      return SharedContentResult(
        isOpenedFromShare: false,
        content: null,
      );
    } catch (e) {
      debugPrint('Unexpected error getting initial shared content: $e');
      return SharedContentResult(
        isOpenedFromShare: false,
        content: null,
      );
    }
  }
  
  Future<bool> cancelReturn() async {
    try {
      final bool result = await _channel.invokeMethod('cancelReturn');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error canceling return: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error canceling return: $e');
      return false;
    }
  }
  
  Future<bool> saveContentSuccess() async {
    try {
      final bool result = await _channel.invokeMethod('saveContentSuccess');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error reporting save success: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error reporting save success: $e');
      return false;
    }
  }
  
  Future<bool> saveContentFailure() async {
    try {
      final bool result = await _channel.invokeMethod('saveContentFailure');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error reporting save failure: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error reporting save failure: $e');
      return false;
    }
  }
}

class SharedContentResult {
  final bool isOpenedFromShare;
  final SharedContent? content;
  
  SharedContentResult({
    required this.isOpenedFromShare,
    required this.content,
  });
} 
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
    } catch (e) {
      debugPrint('Unexpected error checking for shared content: $e');
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
    } catch (e) {
      debugPrint('Unexpected error getting shared text: $e');
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
    } catch (e) {
      debugPrint('Unexpected error getting shared image URIs: $e');
      return null;
    }
  }
  
  Future<bool> checkForNewContent() async {
    try {
      final bool hasNewContent = await _channel.invokeMethod('checkForNewContent');
      return hasNewContent;
    } on PlatformException catch (e) {
      debugPrint('Error checking for new content: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking for new content: $e');
      return false;
    }
  }

  Future<bool> cancelRedirect() async {
    try {
      final bool result = await _channel.invokeMethod('cancelRedirect');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error canceling redirect: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error canceling redirect: $e');
      return false;
    }
  }
} 
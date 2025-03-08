import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/shared_content.dart';

class StorageService {
  static const String _sharedContentBoxName = 'shared_content_box';
  static final StorageService _instance = StorageService._internal();
  
  Box<SharedContent>? _sharedContentBox;
  bool _isInitialized = false;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Hive
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SharedContentAdapter());
      }
      
      // Open boxes
      _sharedContentBox = await Hive.openBox<SharedContent>(_sharedContentBoxName);
      
      _isInitialized = true;
      debugPrint('Storage service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing storage service: $e');
      // Fallback to memory storage if there's an error
      Hive.init(null);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SharedContentAdapter());
      }
      _sharedContentBox = await Hive.openBox<SharedContent>(_sharedContentBoxName, path: null);
      _isInitialized = true;
      debugPrint('Initialized with in-memory storage due to error');
    }
  }
  
  Future<void> saveSharedContent(SharedContent content) async {
    await _ensureInitialized();
    
    try {
      await _sharedContentBox!.add(content);
      debugPrint('Saved shared content to storage: ${content.toString()}');
    } catch (e) {
      debugPrint('Error saving shared content: $e');
      rethrow;
    }
  }
  
  List<SharedContent> getAllSharedContent() {
    if (!_isInitialized || _sharedContentBox == null) {
      debugPrint('Storage not initialized, returning empty list');
      return [];
    }
    
    try {
      final List<SharedContent> contents = _sharedContentBox!.values.toList();
      // Sort by timestamp, newest first
      contents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      debugPrint('Retrieved ${contents.length} shared content items from storage');
      return contents;
    } catch (e) {
      debugPrint('Error retrieving shared content: $e');
      return [];
    }
  }
  
  Future<void> clearAllSharedContent() async {
    await _ensureInitialized();
    
    try {
      await _sharedContentBox!.clear();
      debugPrint('Cleared all shared content from storage');
    } catch (e) {
      debugPrint('Error clearing shared content: $e');
      rethrow;
    }
  }
  
  Future<void> deleteSharedContent(int index) async {
    await _ensureInitialized();
    
    try {
      await _sharedContentBox!.deleteAt(index);
      debugPrint('Deleted shared content at index $index');
    } catch (e) {
      debugPrint('Error deleting shared content: $e');
      rethrow;
    }
  }
  
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }
  
  // For testing and debugging
  Future<void> printAllContent() async {
    await _ensureInitialized();
    
    final contents = getAllSharedContent();
    debugPrint('All shared content (${contents.length} items):');
    for (int i = 0; i < contents.length; i++) {
      final content = contents[i];
      debugPrint('[$i] ${content.toString()} - ${content.timestamp}');
    }
  }
}

// Temporary adapter until we generate the real one
class SharedContentAdapter extends TypeAdapter<SharedContent> {
  @override
  final int typeId = 0;

  @override
  SharedContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SharedContent(
      text: fields[0] as String?,
      imageUris: (fields[1] as List?)?.cast<String>(),
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SharedContent obj) {
    writer.writeByte(3);
    writer.writeByte(0);
    writer.write(obj.text);
    writer.writeByte(1);
    writer.write(obj.imageUris);
    writer.writeByte(2);
    writer.write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
} 
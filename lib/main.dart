import 'package:flutter/material.dart';
import 'services/share_service.dart';
import 'services/storage_service.dart';
import 'models/shared_content.dart';
import 'dart:io';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive and storage service
  await Hive.initFlutter();
  await StorageService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share Receiver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Share Receiver'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final ShareService _shareService = ShareService();
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  
  // Shared content
  bool _isOpenedFromShare = false;
  SharedContent? _currentContent;
  
  // List to store all shared content
  List<SharedContent> _allSharedContent = [];
  
  // Loading screen state
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  bool _showCountdown = false;
  bool _userInteracted = false;
  String _savingStatus = 'Saving...';
  bool _saveSuccess = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedContent();
    _checkInitialSharedContent();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, check for new content
      _checkInitialSharedContent();
    }
  }
  
  Future<void> _loadSavedContent() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final savedContent = _storageService.getAllSharedContent();
      setState(() {
        _allSharedContent = savedContent;
        debugPrint('Loaded ${_allSharedContent.length} items from storage');
      });
    } catch (e) {
      debugPrint('Error loading saved content: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkInitialSharedContent() async {
    debugPrint('Checking initial shared content...');
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _shareService.getInitialSharedContent();
      
      setState(() {
        _isOpenedFromShare = result.isOpenedFromShare;
        _currentContent = result.content;
        
        // Add to the list of all shared content if it has content
        if (_currentContent != null && _currentContent!.hasContent) {
          _allSharedContent.add(_currentContent!);
          debugPrint('Added new content to list. Total items: ${_allSharedContent.length}');
          
          // Save to storage
          _saveToStorage(_currentContent!);
          
          // Start countdown if opened from share
          if (_isOpenedFromShare) {
            _startCountdown();
          }
        }
        
        _isLoading = false;
      });
      
      // Report success to native side
      if (_currentContent != null && _currentContent!.hasContent) {
        await _shareService.saveContentSuccess();
      }
    } catch (e) {
      debugPrint('Error checking initial shared content: $e');
      
      setState(() {
        _isLoading = false;
        if (_isOpenedFromShare) {
          _saveSuccess = false;
          _savingStatus = 'Failed to save content';
        }
      });
      
      // Report failure to native side
      await _shareService.saveContentFailure();
    }
  }
  
  Future<void> _saveToStorage(SharedContent content) async {
    try {
      await _storageService.saveSharedContent(content);
      _saveSuccess = true;
      debugPrint('Successfully saved content to storage');
    } catch (e) {
      _saveSuccess = false;
      debugPrint('Failed to save content to storage: $e');
    }
  }
  
  void _startCountdown() {
    debugPrint('Starting countdown...');
    
    setState(() {
      _countdownSeconds = 5;
      _showCountdown = true;
      _userInteracted = false;
      _savingStatus = 'Saving...';
    });
    
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
          debugPrint('Countdown: $_countdownSeconds');
        } else {
          _countdownTimer?.cancel();
          
          // Update status before returning
          if (_saveSuccess) {
            _savingStatus = 'Content saved successfully!';
          } else {
            _savingStatus = 'Failed to save content';
          }
          
          // Let the UI update with the final status before returning
          Future.delayed(const Duration(milliseconds: 500), () {
            // The native side will handle the return
          });
        }
      });
    });
  }
  
  void _cancelReturn() {
    if (!_userInteracted) {
      _userInteracted = true;
      _shareService.cancelReturn();
      
      setState(() {
        _showCountdown = false;
        _isOpenedFromShare = false; // No longer treat as opened from share
      });
      
      _countdownTimer?.cancel();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-return cancelled. You\'ll stay in this app.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _deleteContent(int index) async {
    try {
      await _storageService.deleteSharedContent(index);
      setState(() {
        _allSharedContent = _storageService.getAllSharedContent();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting content: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If opened from share and still in countdown, show loading screen
    if (_isOpenedFromShare && (_showCountdown || _countdownSeconds == 0)) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_countdownSeconds > 0)
                const CircularProgressIndicator()
              else
                Icon(
                  _saveSuccess ? Icons.check_circle : Icons.error,
                  color: _saveSuccess ? Colors.green : Colors.red,
                  size: 64,
                ),
              const SizedBox(height: 24),
              Text(
                _savingStatus,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_countdownSeconds > 0)
                Text(
                  'Returning in $_countdownSeconds seconds',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cancelReturn,
                child: const Text('Stay in App'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Normal app view
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedContent,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_allSharedContent.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No shared content',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Share content from other apps to see it here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allSharedContent.length,
      itemBuilder: (context, index) {
        final content = _allSharedContent[index]; // Already sorted in storage service
        return Dismissible(
          key: Key('content_${index}_${content.timestamp.millisecondsSinceEpoch}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _deleteContent(index);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timestamp
                  Text(
                    'Shared on ${_formatDate(content.timestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Content
                  if (content.text != null) ...[
                    const Text(
                      'Shared Text:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableLinkify(
                        text: content.text!,
                        style: const TextStyle(fontSize: 16),
                        linkStyle: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        onOpen: (link) {
                          _launchURL(link.url);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (content.imageUris != null && content.imageUris!.isNotEmpty) ...[
                    const Text(
                      'Shared Images:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: content.imageUris!.length,
                      itemBuilder: (context, imageIndex) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(content.imageUris![imageIndex].replaceFirst('file://', '')),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading image: $error');
                              return Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _launchURL(String urlString) async {
    try {
      await launch(
        urlString,
        forceSafariVC: false,
        forceWebView: false,
        enableJavaScript: true,
      );
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $urlString')),
      );
    }
  }
}

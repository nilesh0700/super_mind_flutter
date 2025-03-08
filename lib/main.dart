import 'package:flutter/material.dart';
import 'services/share_service.dart';
import 'models/shared_content.dart';
import 'dart:io';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

void main() {
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
  SharedContent? _sharedContent;
  final ShareService _shareService = ShareService();
  bool _isLoading = true;
  Timer? _contentCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForSharedContent();
    
    // Set up a timer to periodically check for new content
    _contentCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForNewContent();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contentCheckTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, check for new content
      _checkForNewContent();
    }
  }

  Future<void> _checkForSharedContent() async {
    setState(() {
      _isLoading = true;
    });

    bool hasContent = await _shareService.hasSharedContent();
    
    if (hasContent) {
      String? text = await _shareService.getSharedText();
      List<String>? imageUris = await _shareService.getSharedImageUris();
      
      setState(() {
        _sharedContent = SharedContent(text: text, imageUris: imageUris);
        _isLoading = false;
      });
    } else {
      setState(() {
        _sharedContent = null;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _checkForNewContent() async {
    try {
      bool hasNewContent = await _shareService.checkForNewContent();
      
      if (hasNewContent) {
        _checkForSharedContent();
        
        // Show a notification or highlight that new content was received
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New content received!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Silently handle errors during content checking
      debugPrint('Error checking for new content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkForSharedContent,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_sharedContent == null || !_sharedContent!.hasContent) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sharedContent!.text != null) ...[
            const Text(
              'Shared Text:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableLinkify(
                text: _sharedContent!.text!,
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
            const SizedBox(height: 24),
          ],
          if (_sharedContent!.imageUris != null && _sharedContent!.imageUris!.isNotEmpty) ...[
            const Text(
              'Shared Images:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              itemCount: _sharedContent!.imageUris!.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_sharedContent!.imageUris![index].replaceFirst('file://', '')),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
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
    );
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $urlString')),
      );
    }
  }
}

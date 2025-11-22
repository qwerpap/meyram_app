import 'package:flutter/material.dart';
import 'presentation/pages/webview_page_url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meyram',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Switch between WebViewPage and WebViewPageUrlLauncher to test
      home: const WebViewPageUrlLauncher(), // Using url_launcher for now
      // home: const WebViewPage(), // Original WebView implementation
    );
  }
}

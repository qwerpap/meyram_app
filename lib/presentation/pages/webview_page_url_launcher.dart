import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';

/// WebView page using url_launcher (opens in system browser)
class WebViewPageUrlLauncher extends StatefulWidget {
  const WebViewPageUrlLauncher({super.key});

  @override
  State<WebViewPageUrlLauncher> createState() => _WebViewPageUrlLauncherState();
}

class _WebViewPageUrlLauncherState extends State<WebViewPageUrlLauncher> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _openUrl();
  }

  Future<void> _openUrl() async {
    final uri = Uri.parse(AppConstants.baseUrl);
    
    try {
      if (!await canLaunchUrl(uri)) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meyram'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Сайт должен открыться в браузере'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _openUrl,
                    child: const Text('Открыть снова'),
                  ),
                ],
              ),
            ),
    );
  }
}

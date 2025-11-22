import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/constants/app_constants.dart';
import '../bloc/webview/webview_cubit.dart';
import '../bloc/webview/webview_state.dart';

/// WebView page using flutter_inappwebview (better control, especially for iOS)
class WebViewPageInApp extends StatelessWidget {
  const WebViewPageInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WebViewCubit()..setLoading(true),
      child: const _WebViewContent(),
    );
  }
}

class _WebViewContent extends StatefulWidget {
  const _WebViewContent();

  @override
  State<_WebViewContent> createState() => _WebViewContentState();
}

class _WebViewContentState extends State<_WebViewContent> {
  bool _isLoading = true;

  final String userAgent = Platform.isIOS
      ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
      : 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36';

  // User Script to mask WebView BEFORE page loads - CRITICAL for iOS
  final UserScript maskWebViewScript = UserScript(
    source: '''
      (function() {
        // Execute IMMEDIATELY before any site JavaScript runs
        // This is the key to bypassing WebView detection
        
        // Remove standalone property (iOS WebView detection)
        try {
          Object.defineProperty(navigator, 'standalone', {
            get: function() { return false; },
            configurable: true,
            enumerable: false
          });
        } catch(e) {}
        
        // Remove webdriver property (automation/WebView detection)
        try {
          Object.defineProperty(navigator, 'webdriver', {
            get: function() { return false; },
            configurable: true,
            enumerable: false
          });
        } catch(e) {}
        
        // Set vendor to Apple (like Safari)
        try {
          Object.defineProperty(navigator, 'vendor', {
            get: function() { return 'Apple Computer, Inc.'; },
            configurable: true
          });
        } catch(e) {}
        
        // Remove WebKit message handlers (iOS WebView specific)
        try {
          if (window.webkit && window.webkit.messageHandlers) {
            delete window.webkit.messageHandlers;
          }
        } catch(e) {}
        
        // Override any detection attempts
        try {
          const originalHasOwnProperty = Object.prototype.hasOwnProperty;
          Object.prototype.hasOwnProperty = function(prop) {
            if (prop === 'standalone' || prop === 'webdriver') {
              return false;
            }
            return originalHasOwnProperty.call(this, prop);
          };
        } catch(e) {}
      })();
    ''',
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<WebViewCubit, WebViewState>(
        builder: (context, state) {
          return Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(AppConstants.baseUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  userAgent: userAgent,
                  // iOS-specific settings (most important)
                  allowsInlineMediaPlayback: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsBackForwardNavigationGestures: true,
                  // Disable WebView detection
                  suppressesIncrementalRendering: false,
                  // Android settings (less important, but keep for compatibility)
                  useHybridComposition: true,
                ),
                onWebViewCreated: (controller) {
                  // Add user script to mask WebView BEFORE page loads
                  controller.addUserScript(userScript: maskWebViewScript);
                },
                onLoadStart: (controller, url) {
                  context.read<WebViewCubit>().onPageStarted(url.toString());
                },
                onLoadStop: (controller, url) async {
                  context.read<WebViewCubit>().onPageFinished(url.toString());
                  
                  // iOS needs more time for WKWebView to render
                  final delay = Platform.isIOS ? 2000 : 1000;
                  await Future.delayed(Duration(milliseconds: delay));
                  
                  // Aggressive content visibility forcing for iOS
                  for (int i = 0; i < 5; i++) {
                    await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
                    
                    await controller.evaluateJavascript(source: '''
                      (function() {
                        const body = document.body;
                        const html = document.documentElement;
                        
                        if (body && html) {
                          // Force visibility
                          html.style.visibility = 'visible';
                          html.style.opacity = '1';
                          html.style.display = 'block';
                          body.style.visibility = 'visible';
                          body.style.opacity = '1';
                          body.style.display = 'block';
                          body.style.height = 'auto';
                          body.style.minHeight = '100vh';
                          
                          // Show ALL elements recursively
                          function showAll(elem) {
                            if (!elem) return;
                            if (elem.style) {
                              elem.style.visibility = 'visible';
                              if (elem.style.display === 'none') elem.style.display = '';
                              if (elem.style.opacity === '0') elem.style.opacity = '1';
                            }
                            for (let child of elem.children) {
                              showAll(child);
                            }
                          }
                          
                          showAll(body);
                          
                          // Force reflow
                          body.offsetHeight;
                          html.offsetHeight;
                        }
                      })();
                    ''');
                  }
                  
                  setState(() {
                    _isLoading = false;
                  });
                },
                onReceivedError: (controller, request, error) {
                  context.read<WebViewCubit>().onWebResourceError(error.description);
                },
                onProgressChanged: (controller, progress) {
                  if (progress == 100) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
              ),
              if (state.isLoading || _isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              if (state.error != null)
                Center(
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}


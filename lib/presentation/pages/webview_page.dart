import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../bloc/webview/webview_cubit.dart';
import '../bloc/webview/webview_state.dart';

class WebViewPage extends StatelessWidget {
  const WebViewPage({super.key});

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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final cubit = context.read<WebViewCubit>();
    
    // Simple WebViewController without platform-specific settings
    final WebViewController controller = WebViewController();

    // Use Safari-like User Agent for iOS to avoid detection as WebView
    final String userAgent = Platform.isIOS
        ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
        : 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36';

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress if needed
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation requests including redirects
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            cubit.onPageStarted(url);
            cubit.setCurrentUrl(url);
            
            // CRITICAL: Mask WebView immediately when page starts loading
            // This prevents site from detecting WebView and blocking content
            if (Platform.isIOS) {
              controller.runJavaScript('''
                (function() {
                  // Remove WebView detection immediately
                  try {
                    Object.defineProperty(navigator, 'standalone', {
                      get: function() { return false; },
                      configurable: true
                    });
                  } catch(e) {}
                  
                  try {
                    Object.defineProperty(navigator, 'webdriver', {
                      get: function() { return false; },
                      configurable: true
                    });
                  } catch(e) {}
                  
                  // Make it look like Safari
                  try {
                    if (!navigator.vendor || navigator.vendor.indexOf('Apple') === -1) {
                      Object.defineProperty(navigator, 'vendor', {
                        get: function() { return 'Apple Computer, Inc.'; },
                        configurable: true
                      });
                    }
                  } catch(e) {}
                })();
              ''');
            }
          },
          onPageFinished: (String url) async {
            cubit.onPageFinished(url);
            cubit.setCurrentUrl(url);
            
            // CRITICAL: Mask WebView as regular browser to prevent site blocking
            // Site detects WebView and hides content - we need to trick it
            try {
              await controller.runJavaScript('''
                (function() {
                  // Remove WebView detection properties
                  if (navigator.standalone !== undefined) {
                    Object.defineProperty(navigator, 'standalone', {
                      get: function() { return false; },
                      configurable: true
                    });
                  }
                  
                  // Remove webdriver property (indicates automation/WebView)
                  Object.defineProperty(navigator, 'webdriver', {
                    get: function() { return false; },
                    configurable: true
                  });
                  
                  // Add Safari-like properties for iOS
                  if (!window.chrome) {
                    Object.defineProperty(window, 'chrome', {
                      get: function() { return undefined; },
                      configurable: true
                    });
                  }
                  
                  // Ensure we look like Safari
                  if (navigator.vendor && navigator.vendor.indexOf('Apple') === -1) {
                    Object.defineProperty(navigator, 'vendor', {
                      get: function() { return 'Apple Computer, Inc.'; },
                      configurable: true
                    });
                  }
                  
                  // Force visibility immediately
                  const body = document.body;
                  const html = document.documentElement;
                  if (body && html) {
                    html.style.visibility = 'visible';
                    html.style.opacity = '1';
                    html.style.display = 'block';
                    body.style.visibility = 'visible';
                    body.style.opacity = '1';
                    body.style.display = 'block';
                  }
                })();
              ''');
            } catch (e) {
              // Ignore errors
            }
            
            // Wait for site to render after masking
            final delay = Platform.isIOS ? 2000 : 1000;
            await Future.delayed(Duration(milliseconds: delay));
            
            // Force content to render - wait for JavaScript frameworks
            for (int i = 0; i < 15; i++) {
              await Future.delayed(const Duration(milliseconds: 500));
              try {
                final hasContent = await controller.runJavaScriptReturningResult('''
                  (function() {
                    // Wait for document ready
                    if (document.readyState !== 'complete') {
                      return false;
                    }
                    
                    const body = document.body;
                    if (!body) return false;
                    
                    // Remove ALL hiding styles from body and html
                    document.documentElement.style.visibility = 'visible';
                    document.documentElement.style.opacity = '1';
                    document.documentElement.style.display = 'block';
                    body.style.visibility = 'visible';
                    body.style.opacity = '1';
                    body.style.display = 'block';
                    body.style.height = 'auto';
                    body.style.overflow = 'visible';
                    
                    // Force visibility of ALL elements recursively
                    function showAllElements(element) {
                      if (!element) return;
                      
                      // Show current element
                      if (element.style) {
                        if (element.style.visibility === 'hidden' || 
                            element.style.visibility === 'collapse') {
                          element.style.visibility = 'visible';
                        }
                        if (element.style.display === 'none') {
                          element.style.display = '';
                        }
                        if (element.style.opacity === '0' || element.style.opacity === '') {
                          element.style.opacity = '1';
                        }
                        if (element.style.height === '0px' || element.style.height === '0') {
                          element.style.height = 'auto';
                        }
                        if (element.style.maxHeight === '0px' || element.style.maxHeight === '0') {
                          element.style.maxHeight = 'none';
                        }
                      }
                      
                      // Show all children
                      for (let child of element.children) {
                        showAllElements(child);
                      }
                    }
                    
                    showAllElements(body);
                    
                    // Trigger window load event in case site is waiting for it
                    if (typeof window !== 'undefined') {
                      window.dispatchEvent(new Event('load'));
                      window.dispatchEvent(new Event('DOMContentLoaded'));
                    }
                    
                    // Check if we have meaningful content
                    const hasForm = document.querySelector('form') !== null;
                    const hasInputs = document.querySelectorAll('input').length > 0;
                    const hasButtons = document.querySelectorAll('button').length > 0;
                    const bodyText = body.innerText || body.textContent || '';
                    const hasText = bodyText.trim().length > 50;
                    const hasChildren = body.children.length > 0;
                    
                    return hasForm || hasInputs || hasButtons || (hasText && hasChildren);
                  })();
                ''');
                
                if (hasContent == true) {
                  // Content found, try one more time to ensure it's fully visible
                  await Future.delayed(const Duration(milliseconds: 300));
                  await controller.runJavaScript('''
                    // Final visibility check and fix
                    document.querySelectorAll('*').forEach(el => {
                      if (el.style) {
                        if (el.style.visibility === 'hidden') el.style.visibility = 'visible';
                        if (el.style.display === 'none') el.style.display = '';
                        if (el.style.opacity === '0') el.style.opacity = '1';
                      }
                    });
                  ''');
                  break;
                }
              } catch (e) {
                // Continue trying
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Log resource errors for debugging
            final errorMessage = 'Resource error: ${error.description} (${error.errorCode})';
            cubit.onWebResourceError(errorMessage);
          },
          onHttpError: (HttpResponseError error) {
            // Log HTTP errors
            final errorMessage = 'HTTP error: ${error.response?.statusCode} - ${error.response?.uri}';
            cubit.onWebResourceError(errorMessage);
          },
        ),
      );


    _controller = controller;
    
    // For iOS, try loading with a slight delay to ensure WebView is ready
    if (Platform.isIOS) {
      Future.delayed(const Duration(milliseconds: 100), () {
        controller.loadRequest(Uri.parse(AppConstants.baseUrl));
      });
    } else {
      controller.loadRequest(Uri.parse(AppConstants.baseUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<WebViewCubit, WebViewState>(
        builder: (context, state) {
          return Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (state.isLoading)
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


import 'package:equatable/equatable.dart';

/// State for WebView
class WebViewState extends Equatable {
  const WebViewState({
    this.isLoading = true,
    this.currentUrl,
    this.error,
  });

  final bool isLoading;
  final String? currentUrl;
  final String? error;

  WebViewState copyWith({
    bool? isLoading,
    String? currentUrl,
    String? error,
  }) {
    return WebViewState(
      isLoading: isLoading ?? this.isLoading,
      currentUrl: currentUrl ?? this.currentUrl,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, currentUrl, error];
}


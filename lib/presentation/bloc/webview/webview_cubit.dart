import 'package:flutter_bloc/flutter_bloc.dart';
import 'webview_state.dart';

/// Cubit for managing WebView state
class WebViewCubit extends Cubit<WebViewState> {
  WebViewCubit() : super(const WebViewState());

  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void setCurrentUrl(String url) {
    emit(state.copyWith(currentUrl: url));
  }

  void setError(String error) {
    emit(state.copyWith(error: error, isLoading: false));
  }

  void onPageStarted(String url) {
    emit(state.copyWith(isLoading: true, currentUrl: url, error: null));
  }

  void onPageFinished(String url) {
    emit(state.copyWith(isLoading: false, currentUrl: url, error: null));
  }

  void onWebResourceError(String errorMessage) {
    emit(state.copyWith(error: errorMessage, isLoading: false));
  }
}


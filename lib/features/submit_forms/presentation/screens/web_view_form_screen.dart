import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../common/widgets/app_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/di/injection.dart';
import '../bloc/submit_forms_bloc.dart';

class WebViewForFormScreen extends StatefulWidget {
  final String? formId;
  final String? formName;
  final String? customUrl;
  const WebViewForFormScreen({
    super.key,
    this.formId,
    this.formName,
    this.customUrl,
  });

  @override
  State<WebViewForFormScreen> createState() => _WebViewForFormScreenState();
}

class _WebViewForFormScreenState extends State<WebViewForFormScreen> {
  WebViewController? _webViewController;
  bool _localLoading = true;

  @override
  void initState() {
    super.initState();

    _initStaticUrl();
  }

  void _initStaticUrl() {
    final token = getIt<SharedPreferences>().getString('auth_token') ?? "";
    if (widget.customUrl != null) {
      _setupWebViewController(widget.customUrl!);
    } else if (widget.formId != null) {
      _setupWebViewController(
        "https://presshop.dev/f/${widget.formId}?token=$token",
      );
    }
  }

  void _setupWebViewController(String url) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FormChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("FormChannel message: ${message.message}");
          if (mounted) Navigator.pop(context);
        },
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("FlutterChannel message: ${message.message}");
          if (mounted) Navigator.pop(context);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint("WebView progress: $progress");
          },
          onPageStarted: (String pageUrl) {
            debugPrint("WebView started loading: $pageUrl");
            final lowerUrl = pageUrl.toLowerCase();
            if (lowerUrl.contains('/success') ||
                lowerUrl.contains('/submitted') ||
                lowerUrl.contains('status=success') ||
                lowerUrl.contains('/thank-you') ||
                lowerUrl.contains('/form-success')) {
              if (mounted) Navigator.pop(context);
            }
          },
          onPageFinished: (String pageUrl) {
            debugPrint("WebView finished loading: $pageUrl");
            if (mounted) {
              setState(() {
                _localLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView error: $error");
          },
          onNavigationRequest: (NavigationRequest request) {
            final lowerUrl = request.url.toLowerCase();
            if (lowerUrl.contains('/success') ||
                lowerUrl.contains('/submitted') ||
                lowerUrl.contains('status=success') ||
                lowerUrl.contains('/thank-you') ||
                lowerUrl.contains('/form-success')) {
              if (mounted) Navigator.pop(context);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final showWebView = widget.customUrl != null || widget.formId != null;

    return BlocProvider<SubmitFormsBloc>(
      create: (context) {
        final bloc = getIt<SubmitFormsBloc>();
        if (!showWebView) {
          bloc.add(const FetchAppTokenUrlEvent());
        }
        return bloc;
      },
      child: BlocConsumer<SubmitFormsBloc, SubmitFormsState>(
        listener: (context, state) {
          if (state.appTokenUrl != null && _webViewController == null) {
            _setupWebViewController(state.appTokenUrl!);
          }
        },
        builder: (context, state) {
          final isLoading = showWebView
              ? _localLoading
              : (state.isAppTokenLoading || _webViewController == null);
          final errorMessage = showWebView ? null : state.appTokenError;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final navigator = Navigator.of(context);
              if (_webViewController != null && await _webViewController!.canGoBack()) {
                _webViewController!.goBack();
              } else {
                navigator.pop();
              }
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F6FA),
              appBar: AppAppBar(
                title: widget.formName ?? 'Forms',
                elevation: 0.5,
                centerTitle: false,
                titleSpacing: 0,
                showBack: true,
                onBackTap: () async {
                  final navigator = Navigator.of(context);
                  if (_webViewController != null && await _webViewController!.canGoBack()) {
                    _webViewController!.goBack();
                  } else {
                    navigator.pop();
                  }
                },
              ),
              body: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : WebViewWidget(controller: _webViewController!),
            ),
          );
        },
      ),
    );
  }
}

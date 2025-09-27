import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewOAuthScreen extends StatefulWidget {
  final String title;
  final String authUrl;
  final String redirectUri;

  const WebViewOAuthScreen({
    required this.title,
    required this.authUrl,
    required this.redirectUri,
    super.key,
  });

  @override
  State<WebViewOAuthScreen> createState() => _WebViewOAuthScreenState();
}

class _WebViewOAuthScreenState extends State<WebViewOAuthScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _handleNavigation,
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  void _handleNavigation(String url) {
    if (url.startsWith(widget.redirectUri)) {
      final uri = Uri.parse(url);
      final accessToken = uri.fragment
          .split('&')
          .firstWhere((e) => e.startsWith('access_token='))
          .split('=')[1];
      Navigator.pop(context, {'access_token': accessToken});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

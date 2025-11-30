import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class IframeViewer extends StatefulWidget {
  final String url;

  const IframeViewer({super.key, required this.url});

  @override
  State<IframeViewer> createState() => _IframeViewerState();
}

class _IframeViewerState extends State<IframeViewer> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'iframe-${DateTime.now().millisecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

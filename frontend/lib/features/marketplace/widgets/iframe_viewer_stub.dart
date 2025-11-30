import 'package:flutter/material.dart';

class IframeViewer extends StatelessWidget {
  final String url;

  const IframeViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '3D View available on Web',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

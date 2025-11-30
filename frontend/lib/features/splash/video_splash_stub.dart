// Stub for non-web platforms
import 'package:flutter/material.dart';

/// Creates a placeholder widget for non-web platforms
Widget createVideoSplash({
  required String viewId,
  required VoidCallback onVideoEnd,
}) {
  // Return empty container on non-web platforms
  // The splash page will use fallback UI
  return const SizedBox.shrink();
}

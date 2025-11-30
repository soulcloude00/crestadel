// Web-specific video splash implementation
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class VideoSplashWidget extends StatefulWidget {
  final String viewId;
  final VoidCallback onVideoEnd;
  
  const VideoSplashWidget({
    super.key,
    required this.viewId,
    required this.onVideoEnd,
  });

  @override
  State<VideoSplashWidget> createState() => _VideoSplashWidgetState();
}

class _VideoSplashWidgetState extends State<VideoSplashWidget> {
  bool _registered = false;
  bool _videoReady = false;
  html.VideoElement? _video;
  
  @override
  void initState() {
    super.initState();
    _registerVideoView();
  }

  void _registerVideoView() {
    if (_registered) return;
    
    // Create a container div that will hold our video with cover styling
    final container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.overflow = 'hidden'
      ..style.backgroundColor = '#000';
    
    // Use native video element for full control (no play button overlay)
    // Local video from assets
    _video = html.VideoElement()
      ..src = 'assets/assets/intro.mp4'
      ..autoplay = true
      ..muted = true  // Required for autoplay to work
      ..controls = false  // No controls
      ..setAttribute('playsinline', 'true')
      ..setAttribute('webkit-playsinline', 'true')
      ..style.border = 'none'
      ..style.position = 'absolute'
      ..style.top = '50%'
      ..style.left = '50%'
      ..style.transform = 'translate(-50%, -50%)'
      // Scale up to cover the viewport while maintaining aspect ratio
      ..style.width = 'auto'
      ..style.height = '100%'
      ..style.minWidth = '100%'
      ..style.minHeight = '100%'
      ..style.objectFit = 'cover'
      ..style.pointerEvents = 'none'
      ..style.opacity = '0'
      ..style.transition = 'opacity 0.3s ease-in';
    
    // When video can play, fade it in
    _video!.onCanPlay.listen((_) {
      _video?.style.opacity = '1';
      _video?.play();
      if (mounted) {
        setState(() => _videoReady = true);
      }
    });
    
    // When video ends, trigger callback
    _video!.onEnded.listen((_) {
      widget.onVideoEnd();
    });
    
    container.children.add(_video!);
    
    // Register the view factory
    ui_web.platformViewRegistry.registerViewFactory(
      widget.viewId,
      (int viewId) => container,
    );
    
    _registered = true;
  }
  
  @override
  void dispose() {
    _video?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Loading placeholder while video loads
        AnimatedOpacity(
          opacity: _videoReady ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            color: Colors.black,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
                      ).createShader(bounds),
                      child: const Text(
                        '🏰',
                        style: TextStyle(fontSize: 64),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Video element
        HtmlElementView(viewType: widget.viewId),
      ],
    );
  }
}

/// Creates the video widget for web platform
Widget createVideoSplash({
  required String viewId,
  required VoidCallback onVideoEnd,
}) {
  return VideoSplashWidget(
    viewId: viewId,
    onVideoEnd: onVideoEnd,
  );
}

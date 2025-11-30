import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/features/auth/onboarding_page.dart';
import 'package:propfi/features/home/main_layout.dart';
import 'package:propfi/theme/app_theme.dart';
import 'video_splash_stub.dart' if (dart.library.html) 'video_splash_web.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  bool _videoEnded = false;
  bool _showSkip = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final String _viewId = 'splash-video-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);
    
    // Show skip button after 4 seconds (allowing video to load first)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showSkip = true);
      }
    });
    
    // Auto-navigate after video duration + load time (approximately 10 seconds total)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_videoEnded) {
        _onVideoEnd();
      }
    });
  }

  void _onVideoEnd() {
    if (_videoEnded) return;
    setState(() => _videoEnded = true);
    
    _fadeController.forward().then((_) {
      _navigateToNextScreen();
    });
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final walletService = Provider.of<WalletService>(context, listen: false);
    
    if (walletService.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainLayout(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video Background (Web only)
          if (kIsWeb)
            FadeTransition(
              opacity: _fadeAnimation,
              child: createVideoSplash(
                viewId: _viewId,
                onVideoEnd: _onVideoEnd,
              ),
            )
          else
            // Fallback for non-web platforms
            _buildFallbackSplash(),
          
          // Dark overlay gradient at bottom for branding
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          
          // Branding at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
                  ).createShader(bounds),
                  child: const Text(
                    'CRESTADEL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acquire the World, Define Your Portfolio',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          
          // Skip button
          if (_showSkip)
            Positioned(
              top: 40,
              right: 20,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showSkip ? 1.0 : 0.0,
                child: TextButton.icon(
                  onPressed: _onVideoEnd,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                    ),
                  ),
                  icon: Icon(Icons.skip_next, color: AppTheme.primaryColor, size: 18),
                  label: Text(
                    'Skip',
                    style: TextStyle(color: AppTheme.primaryColor, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackSplash() {
    // Fallback splash for non-web platforms
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0A0F),
            Color(0xFF1A1A2E),
            Color(0xFF0A0A0F),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.2),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 60,
                    spreadRadius: 15,
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
                ).createShader(bounds),
                child: const Text(
                  '🏰',
                  style: TextStyle(fontSize: 56),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

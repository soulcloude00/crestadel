import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/features/auth/setup_profile_page.dart';
import 'package:propfi/features/home/main_layout.dart';
import 'package:propfi/services/wallet_service.dart';
import 'dart:ui';
import 'dart:math' as math;

class AuthLandingPage extends StatefulWidget {
  const AuthLandingPage({super.key});

  @override
  State<AuthLandingPage> createState() => _AuthLandingPageState();
}

class _AuthLandingPageState extends State<AuthLandingPage>
    with TickerProviderStateMixin {
  List<CardanoWallet> _availableWallets = [];
  late AnimationController _backgroundController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  /// Show wallet selector dialog
  Future<void> _showConnectWalletDialog() async {
    final walletService = context.read<WalletService>();
    _availableWallets = await walletService.detectWallets();

    if (!mounted) return;

    // Get all supported wallets
    final allWallets = CardanoWallet.values;
    final undetectedWallets = allWallets
        .where((w) => !_availableWallets.contains(w))
        .toList();

    await showModalBottomSheet<CardanoWallet>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A0B2E).withAlpha(242), // 0.95
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: AppTheme.primaryColor.withAlpha(77), // 0.3
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51), // 0.2
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connect Wallet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                  onPressed: () {
                    Navigator.pop(context);
                    _showConnectWalletDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a wallet to connect to Crestadel',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Detected Wallets
            if (_availableWallets.isNotEmpty) ...[
              const Text(
                'Detected',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._availableWallets.map(
                (wallet) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryColor.withAlpha(128), // 0.5
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.primaryColor.withAlpha(26), // 0.1
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      wallet.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _connectWallet(wallet);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Undetected Wallets
            if (undetectedWallets.isNotEmpty) ...[
              const Text(
                'Other Supported Wallets (Manual Connect)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...undetectedWallets.map(
                (wallet) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withAlpha(26), // 0.1
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withAlpha(13), // 0.05
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.grey[400],
                    ),
                    title: Text(
                      wallet.displayName,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _connectWallet(wallet);
                    },
                  ),
                ),
              ),
            ],

            const Divider(color: Colors.grey),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withAlpha(26), // 0.1
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withAlpha(13), // 0.05
              ),
              child: ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: Colors.cyan),
                title: const Text(
                  'Mobile Wallet (P2P)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Connect via CIP-45 (Vespr, Eternl)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _connectMobileWallet();
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _connectMobileWallet() async {
    final walletService = context.read<WalletService>();
    final qrData = await walletService.connectMobileWallet();

    if (!mounted) return;

    if (qrData != null) {
      final connectionFuture = walletService.waitForMobileConnection();
      bool dialogOpen = true;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A0B2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppTheme.primaryColor.withAlpha(77), // 0.3
            ),
          ),
          title: const Text(
            'Scan to Connect',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(qrData)}',
                  width: 200,
                  height: 200,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan with your mobile wallet (Vespr, Eternl) to connect.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ).then((_) => dialogOpen = false);

      final success = await connectionFuture;

      if (!mounted) return;

      if (success) {
        if (dialogOpen) {
          Navigator.of(context).pop();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initialize Peer Connect'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _connectWallet(CardanoWallet wallet) async {
    final walletService = context.read<WalletService>();
    final success = await walletService.connectWallet(wallet);

    if (!mounted) return;

    if (success) {
      await walletService.completeLogin();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${walletService.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF000000),
                  Color(0xFF1A0B2E),
                  Color(0xFF050505),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Gold Orb
                  Positioned(
                    top:
                        -100 +
                        (math.sin(_backgroundController.value * 2 * math.pi) *
                            50),
                    right:
                        -100 +
                        (math.cos(_backgroundController.value * 2 * math.pi) *
                            50),
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withAlpha(26), // 0.1
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withAlpha(26),
                            blurRadius: 120,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Purple Orb
                  Positioned(
                    bottom:
                        -50 +
                        (math.cos(_backgroundController.value * 2 * math.pi) *
                            50),
                    left:
                        -50 +
                        (math.sin(_backgroundController.value * 2 * math.pi) *
                            50),
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purple.withAlpha(38), // 0.15
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withAlpha(38),
                            blurRadius: 120,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Glass Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withAlpha(26), // 0.1
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withAlpha(
                                  77,
                                ), // 0.3
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/crestadel_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const Spacer(),

                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFD4AF37),
                            Color(0xFFFFD700),
                            Color(0xFFD4AF37),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Welcome to\nCrestadel',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: -1.0,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Acquire the World, Define Your Portfolio',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'The royal court of decentralized real estate. Join the crypto nobility today.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[300],
                          height: 1.6,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Buttons
                      _buildButton(
                        context,
                        'CONNECT WALLET',
                        Icons.account_balance_wallet,
                        AppTheme.primaryColor,
                        Colors.black,
                        _showConnectWalletDialog,
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        context,
                        'JOIN THE REALM',
                        Icons.person_add,
                        Colors.white.withAlpha(26), // 0.1
                        Colors.white,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SetupProfilePage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    IconData icon,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: bgColor == AppTheme.primaryColor
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withAlpha(77), // 0.3
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: bgColor == AppTheme.primaryColor
                ? BorderSide.none
                : BorderSide(color: Colors.white.withAlpha(51)), // 0.2
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

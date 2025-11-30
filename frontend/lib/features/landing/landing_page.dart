import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/services/hydra_trading_service.dart';
import 'package:propfi/features/marketplace/marketplace_page.dart';
import 'package:propfi/features/marketplace/widgets/property_card.dart';
import 'package:propfi/features/notifications/notifications_page.dart';
import 'package:propfi/features/analytics/analytics_page.dart';
import 'package:propfi/features/bonus/bonus_showcase.dart';
import 'package:propfi/features/hydra/hydra_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletService = context.read<WalletService>();
      walletService.fetchListings();
      if (walletService.isConnected) {
        walletService.refreshBalance();
      }
    });
  }

  Future<void> _refreshBalance() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await context.read<WalletService>().refreshBalance();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletService = Provider.of<WalletService>(context);
    final listings = walletService.listings;
    final featuredListings = listings.take(5).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF050505),
                  Color(0xFF1A0B2E),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshBalance,
              color: AppTheme.primaryColor,
              backgroundColor: const Color(0xFF1A0B2E),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, walletService),
                    const SizedBox(height: 32),
                    _buildRoyalTreasuryCard(context, walletService),
                    const SizedBox(height: 24),
                    _buildMarketStats(context, walletService),
                    const SizedBox(height: 32),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    _buildFeaturedProperties(context, featuredListings),
                    const SizedBox(height: 32),
                    _buildRecentActivity(context, walletService),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WalletService walletService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              walletService.userName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildHydraStatus(context),
            const SizedBox(width: 8),
            _buildIconButton(
              context,
              Icons.emoji_events,
              const Color(0xFFFFD700),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BonusFeaturesShowcase(),
                ),
              ),
            ),
            _buildIconButton(
              context,
              Icons.analytics_outlined,
              Colors.white,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsPage()),
              ),
            ),
            NotificationBell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildProfileMenu(context, walletService),
          ],
        ),
      ],
    );
  }

  Widget _buildHydraStatus(BuildContext context) {
    return Consumer<HydraTradingService>(
      builder: (context, hydraService, _) {
        final isConnected = hydraService.isConnected;
        final isOpen = hydraService.isOpen;
        final color = isOpen
            ? Colors.green
            : isConnected
            ? Colors.blue
            : Colors.grey;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HydraPage()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(51), // 0.2
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOpen ? Icons.bolt : Icons.water_drop,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'L2',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color),
    );
  }

  Widget _buildProfileMenu(BuildContext context, WalletService walletService) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'logout') {
          await context.read<WalletService>().disconnectWallet();
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
      },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1a1a2e),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'wallet',
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                walletService.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${walletService.balance.toStringAsFixed(2)} ₳',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent, size: 20),
              SizedBox(width: 12),
              Text(
                'Disconnect Wallet',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primaryColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withAlpha(77), // 0.3
              blurRadius: 10,
            ),
          ],
        ),
        child: const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF1a1a2e),
          child: Text('👑', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildRoyalTreasuryCard(
    BuildContext context,
    WalletService walletService,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1a1a2e),
            AppTheme.primaryColor.withAlpha(38), // 0.15
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(77), // 0.3
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(51), // 0.2
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Royal Treasury',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🏰 CRESTADEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFD4AF37),
                          Color(0xFFFFD700),
                          Color(0xFFD4AF37),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        '\$${(walletService.balance * 0.35).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${walletService.balance.toStringAsFixed(2)} ₳',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (walletService.isConnected)
                IconButton(
                  onPressed: _isRefreshing ? null : _refreshBalance,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD4AF37),
                          ),
                        )
                      : const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
                  tooltip: 'Refresh Balance',
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Daily Yield',
                '+\$0.00',
                Icons.trending_up,
                Colors.greenAccent,
              ),
              _buildSummaryItem(
                'Estates',
                '${walletService.holdings.length}',
                Icons.apartment,
                Colors.blueAccent,
              ),
              _buildSummaryItem(
                'Crown Rank',
                'Lvl ${walletService.userLevel}',
                Icons.military_tech,
                Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketStats(BuildContext context, WalletService walletService) {
    // Calculate stats from listings
    double tvl = 0;
    double totalApy = 0;
    double volume = 0;
    int listingCount = walletService.listings.length;

    if (listingCount > 0) {
      for (var listing in walletService.listings) {
        tvl += listing.targetAmount;
        totalApy += listing.apy;
        volume += listing.fundsRaised;
      }
    }

    final avgApy = listingCount > 0 ? totalApy / listingCount : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'TVL',
            '\$${(tvl / 1000000).toStringAsFixed(1)}M',
            Icons.lock_clock,
            Colors.cyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'APY',
            '${avgApy.toStringAsFixed(1)}%',
            Icons.percent,
            Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Vol',
            '\$${(volume / 1000).toStringAsFixed(0)}K',
            Icons.bar_chart,
            Colors.purpleAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13), // 0.05
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(26)), // 0.1
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Royal Commands',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Acquire',
                Icons.add_business,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                context,
                'Trade',
                Icons.swap_horiz,
                Colors.white.withAlpha(26), // 0.1
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                context,
                'Claim',
                Icons.savings,
                Colors.white.withAlpha(26), // 0.1
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        if (label == 'Acquire' || label == 'Trade') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MarketplacePage()),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: color == AppTheme.primaryColor
              ? null
              : Border.all(color: Colors.white.withAlpha(26)), // 0.1
          boxShadow: color == AppTheme.primaryColor
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withAlpha(77), // 0.3
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProperties(
    BuildContext context,
    List<MarketplaceListing> featuredListings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Properties',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MarketplacePage(),
                  ),
                );
              },
              child: const Text(
                'See All',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: featuredListings.isEmpty
              ? Center(
                  child: Text(
                    'No featured properties',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredListings.length,
                  itemBuilder: (context, index) {
                    final listing = featuredListings[index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      child: PropertyCard(
                        title: listing.propertyName,
                        location: listing.location,
                        imageUrl: listing.imageUrl,
                        price: listing.price,
                        apy: 8.5 + index,
                        fundedPercentage: listing.fundedPercentage,
                        fundsRaised: listing.fundsRaised,
                        targetAmount: listing.targetAmount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MarketplacePage(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    WalletService walletService,
  ) {
    final transactions = walletService.transactionHistory.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13), // 0.05
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(26)), // 0.1
          ),
          child: transactions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < transactions.length; i++) ...[
                      _buildTransactionItem(transactions[i]),
                      if (i < transactions.length - 1)
                        Divider(color: Colors.white.withAlpha(13), height: 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionRecord tx) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (tx.type) {
      case TransactionType.buy:
        icon = Icons.arrow_upward;
        color = Colors.redAccent; // Money leaving
        title = 'Investment';
        subtitle = tx.propertyName ?? 'Unknown Property';
        break;
      case TransactionType.sell:
        icon = Icons.arrow_downward;
        color = Colors.greenAccent; // Money entering
        title = 'Property Sold';
        subtitle = tx.propertyName ?? 'Unknown Property';
        break;
      case TransactionType.receive:
        icon = Icons.arrow_downward;
        color = Colors.greenAccent;
        title = 'Received Funds';
        subtitle = 'From external wallet';
        break;
      case TransactionType.send:
        icon = Icons.arrow_upward;
        color = Colors.redAccent;
        title = 'Sent Funds';
        subtitle = 'To external wallet';
        break;
    }

    final timeAgo = _getTimeAgo(tx.timestamp);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(26), // 0.1
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${tx.type == TransactionType.receive || tx.type == TransactionType.sell ? '+' : '-'}${tx.amount.toStringAsFixed(0)} ₳',
            style: TextStyle(
              color:
                  tx.type == TransactionType.receive ||
                      tx.type == TransactionType.sell
                  ? Colors.greenAccent
                  : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

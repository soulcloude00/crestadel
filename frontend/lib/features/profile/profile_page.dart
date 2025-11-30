import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/features/profile/edit_profile_page.dart';
import 'dart:ui';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletService = Provider.of<WalletService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        title: Text(
          'MY PROFILE',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF050505),
                    Color(0xFF1A0B2E),
                    Color(0xFF001F24),
                  ],
                ),
              ),
            ),
          ),

          // Content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
                  child: Column(
                    children: [
                      _buildProfileHeader(context, walletService),
                      const SizedBox(height: 24),
                      _buildWalletCard(context, walletService),
                      const SizedBox(height: 24),
                      _buildStatsRow(context, walletService),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryColor,
                    indicatorWeight: 3,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Portfolio'),
                      Tab(text: 'Activity'),
                      Tab(text: 'Achievements'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildPortfolioTab(context, walletService),
                _buildActivityTab(context),
                _buildAchievementsTab(context, walletService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WalletService walletService) {
    final int level = walletService.userLevel;
    final int xp = walletService.userXp;
    final int nextLevelXp = walletService.nextLevelXp;
    final double progress = nextLevelXp > 0 ? xp / nextLevelXp : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with level badge
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://api.dicebear.com/7.x/avataaars/png?seed=${walletService.userName}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black,
                          child: const Icon(Icons.person, size: 45, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        'LV $level',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            walletService.userName.isEmpty ? 'Anonymous Investor' : walletService.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 18),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfilePage()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      walletService.userBio.isEmpty ? 'Real Estate Enthusiast 🏠' : walletService.userBio,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$xp/$nextLevelXp XP',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFollowStat('Following', '234'),
              Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
              _buildFollowStat('Followers', '1.2K'),
              Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
              _buildFollowStat('Investments', '${walletService.holdings.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _buildWalletCard(BuildContext context, WalletService walletService) {
    final isConnected = walletService.status == WalletConnectionStatus.connected;
    final address = walletService.walletAddress ?? '';
    final shortAddress = address.isNotEmpty 
        ? '${address.substring(0, 12)}...${address.substring(address.length - 8)}'
        : 'Not connected';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1A2E), AppTheme.primaryColor.withValues(alpha: 0.15)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConnected ? Icons.account_balance_wallet : Icons.wallet_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? (walletService.connectedWallet?.displayName ?? 'Wallet') : 'Wallet',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: isConnected ? Colors.green : Colors.orange, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(isConnected ? 'Connected' : 'Disconnected', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              if (isConnected)
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                  onPressed: () {
                    if (address.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: address));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!')));
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Text(shortAddress, style: TextStyle(color: Colors.grey[400], fontFamily: 'monospace', fontSize: 13)),
                const Spacer(),
                Text('${walletService.balance.toStringAsFixed(2)} ₳', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, WalletService walletService) {
    final totalValue = walletService.holdings.fold<double>(0, (sum, h) => sum + h.currentValue);
    final monthlyIncome = totalValue * 0.008;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Portfolio Value', '\$${totalValue.toStringAsFixed(0)}', Icons.trending_up, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Monthly Yield', '\$${monthlyIncome.toStringAsFixed(0)}', Icons.payments, AppTheme.primaryColor)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Rank', '#${42 + walletService.userLevel}', Icons.leaderboard, Colors.purple)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  bool _isRefreshing = false;

  Future<void> _refreshPortfolio(WalletService walletService) async {
    setState(() => _isRefreshing = true);
    try {
      await walletService.fetchOnChainPurchases();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Widget _buildPortfolioTab(BuildContext context, WalletService walletService) {
    final holdings = walletService.holdings;
    
    return Column(
      children: [
        // Refresh button header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('YOUR HOLDINGS', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11)),
              const Spacer(),
              GestureDetector(
                onTap: _isRefreshing ? null : () => _refreshPortfolio(walletService),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isRefreshing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                          : const Icon(Icons.refresh, color: AppTheme.primaryColor, size: 14),
                      const SizedBox(width: 6),
                      Text(_isRefreshing ? 'Syncing...' : 'Refresh', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Holdings list
        Expanded(
          child: holdings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apartment_outlined, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text('No properties yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Start investing to build your portfolio', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _refreshPortfolio(walletService),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Sync Holdings'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.black),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: holdings.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildAllocationChart(holdings);
                    return _buildPortfolioItem(holdings[index - 1]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAllocationChart(List<PropertyHolding> holdings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PORTFOLIO ALLOCATION', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 100, height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(value: 1.0, strokeWidth: 10, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${holdings.length}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Assets', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAllocationItem('Residential', 0.65, AppTheme.primaryColor),
                    const SizedBox(height: 8),
                    _buildAllocationItem('Commercial', 0.25, Colors.blue),
                    const SizedBox(height: 8),
                    _buildAllocationItem('Land', 0.10, Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationItem(String label, double percentage, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12))),
        Text('${(percentage * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildPortfolioItem(PropertyHolding holding) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(holding.imageUrl, width: 70, height: 70, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey[900], child: const Icon(Icons.apartment, color: Colors.grey))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holding.propertyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${holding.fractionsOwned} fractions', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.trending_up, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text('+${holding.profitLoss.toStringAsFixed(1)}% ROI', style: TextStyle(color: holding.profitLoss >= 0 ? Colors.green : Colors.red, fontSize: 12)),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${holding.currentValue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: const Text('+12.5%', style: TextStyle(color: Colors.green, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context) {
    final walletService = Provider.of<WalletService>(context);
    final transactions = walletService.transactionHistory;
    
    // Combine real transactions with demo activities
    final activities = <Map<String, dynamic>>[
      ...transactions.map((t) => {
        'type': t.type == TransactionType.buy ? 'buy' : (t.type == TransactionType.sell ? 'sell' : 'yield'),
        'title': t.type == TransactionType.buy ? 'Purchased ${t.fractions} fractions' : 
                 t.type == TransactionType.sell ? 'Sold ${t.fractions} fractions' : 'Yield received',
        'property': t.propertyName ?? 'Property',
        'time': _formatTimeAgo(t.timestamp),
        'amount': t.type == TransactionType.buy ? '+${t.fractions}' : 
                  t.type == TransactionType.sell ? '-${t.fractions}' : '+\$${t.amount.toStringAsFixed(2)}',
        'txHash': t.txHash,
      }),
    ];
    
    // Add demo data if no real transactions
    if (activities.isEmpty) {
      activities.addAll([
        {'type': 'buy', 'title': 'Purchased 25 fractions', 'property': 'Tokyo Sky Residence', 'time': '2 hours ago', 'amount': '+25', 'txHash': null},
        {'type': 'yield', 'title': 'Yield received', 'property': 'Dubai Marina Villa', 'time': '1 day ago', 'amount': '+\$45.00', 'txHash': null},
      ]);
    }

    return Column(
      children: [
        // Header with See All
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('TRANSACTION HISTORY', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAllTransactions(context, walletService),
                child: Text('See All', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Expanded(
          child: activities.isEmpty
              ? Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey[500])))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activities.length > 5 ? 5 : activities.length, // Show only 5 in tab
                  itemBuilder: (context, index) => _buildActivityItem(activities[index]),
                ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final isBuy = activity['type'] == 'buy';
    final isYield = activity['type'] == 'yield';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isYield ? Colors.green : (isBuy ? AppTheme.primaryColor : Colors.red)).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isYield ? Icons.payments : (isBuy ? Icons.add_circle : Icons.remove_circle),
              color: isYield ? Colors.green : (isBuy ? AppTheme.primaryColor : Colors.red), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(activity['property']!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 2),
                Text(activity['time']!, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
          Text(activity['amount']!, style: TextStyle(color: activity['type'] == 'sell' ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  void _showAllTransactions(BuildContext context, WalletService walletService) {
    final transactions = walletService.transactionHistory;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  const Text('All Transactions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${transactions.length} total', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            // Transaction list
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text('No transactions yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Your transaction history will appear here', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final t = transactions[index];
                        return _buildTransactionDetailCard(t);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetailCard(TransactionRecord transaction) {
    final isBuy = transaction.type == TransactionType.buy;
    final isYield = transaction.type == TransactionType.receive;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isYield ? Colors.green : (isBuy ? AppTheme.primaryColor : Colors.red)).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isYield ? Icons.payments : (isBuy ? Icons.add_circle : Icons.remove_circle),
                  color: isYield ? Colors.green : (isBuy ? AppTheme.primaryColor : Colors.red), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBuy ? 'Purchased ${transaction.fractions} fractions' : 
                      isYield ? 'Yield received' : 'Sold ${transaction.fractions} fractions',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(transaction.propertyName ?? 'Property', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isBuy ? '+${transaction.fractions}' : '\$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(color: isBuy ? Colors.green : (isYield ? Colors.green : Colors.red), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(_formatTimeAgo(transaction.timestamp), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ),
            ],
          ),
          if (transaction.txHash != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, color: Colors.grey, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TX: ${transaction.txHash!.substring(0, 20)}...',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: transaction.txHash!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TX Hash copied!')));
                    },
                    child: const Icon(Icons.copy, color: AppTheme.primaryColor, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(BuildContext context, WalletService walletService) {
    final achievements = [
      {'title': 'First Investment', 'desc': 'Made your first property investment', 'icon': Icons.star, 'unlocked': true},
      {'title': 'Diversified', 'desc': 'Own fractions in 3+ properties', 'icon': Icons.grid_view, 'unlocked': true},
      {'title': 'Yield Hunter', 'desc': 'Earned \$100 in yields', 'icon': Icons.attach_money, 'unlocked': true},
      {'title': 'Diamond Hands', 'desc': 'Hold for 30+ days', 'icon': Icons.diamond, 'unlocked': false},
      {'title': 'Whale', 'desc': 'Portfolio value over \$10,000', 'icon': Icons.water, 'unlocked': false},
      {'title': 'Community Leader', 'desc': 'Get 100 followers', 'icon': Icons.people, 'unlocked': false},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final unlocked = achievement['unlocked'] as bool;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unlocked ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: unlocked ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: unlocked ? AppTheme.primaryColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(achievement['icon'] as IconData, color: unlocked ? AppTheme.primaryColor : Colors.grey, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(achievement['title'] as String, style: TextStyle(color: unlocked ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(achievement['desc'] as String, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              if (unlocked) const Icon(Icons.check_circle, color: Colors.green, size: 24)
              else Icon(Icons.lock_outline, color: Colors.grey[600], size: 20),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingsItem(Icons.notifications_outlined, 'Notifications', () {}),
            _buildSettingsItem(Icons.security, 'Security', () {}),
            _buildSettingsItem(Icons.help_outline, 'Help & Support', () {}),
            _buildSettingsItem(Icons.info_outline, 'About Crestadel', () {}),
            const SizedBox(height: 16),
            _buildSettingsItem(Icons.logout, 'Disconnect Wallet', () {
              Provider.of<WalletService>(context, listen: false).disconnectWallet();
              Navigator.pop(context);
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.white),
      title: Text(label, style: TextStyle(color: isDestructive ? Colors.red : Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: const Color(0xFF0A0A0F), child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}

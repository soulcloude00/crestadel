import 'package:flutter/material.dart';
import 'package:propfi/theme/app_theme.dart';
import 'dart:ui';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock user data with real-looking profile pictures from DiceBear
  final List<Map<String, dynamic>> _trendingProperties = [
    {
      'name': 'Sky Tower Penthouse',
      'location': 'Tokyo, Japan',
      'image': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400',
      'funded': 0.92,
      'timeLeft': '4h left',
      'tag': 'HOT',
      'price': '\$2.4M',
    },
    {
      'name': 'Marina Bay Villa',
      'location': 'Dubai, UAE',
      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=400',
      'funded': 0.78,
      'timeLeft': '2 days left',
      'tag': 'TRENDING',
      'price': '\$5.1M',
    },
    {
      'name': 'Central Park Loft',
      'location': 'New York, USA',
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400',
      'funded': 0.65,
      'timeLeft': '5 days left',
      'tag': 'NEW',
      'price': '\$3.8M',
    },
  ];

  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'user': 'Alex Chen',
      'avatar': 'https://i.pravatar.cc/150?img=11',
      'handle': '@alexinvestor',
      'verified': true,
      'time': '2h ago',
      'content': 'Just acquired 50 fractions of the Tokyo Sky Tower! 🏙️ This property has 12% projected APY. Who else is in on this one? #Crestadel #RealEstateTokenization',
      'image': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600',
      'likes': 124,
      'comments': 18,
      'shares': 5,
      'liked': false,
    },
    {
      'id': '2',
      'user': 'Sarah Williams',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'handle': '@sarahw_crypto',
      'verified': true,
      'time': '5h ago',
      'content': 'Monthly yield just hit my wallet! 💰 \$245 passive income from my Dubai Marina holding. Love how transparent the whole process is on-chain.',
      'image': null,
      'likes': 89,
      'comments': 12,
      'shares': 3,
      'liked': true,
    },
    {
      'id': '3',
      'user': 'Michael Torres',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'handle': '@miketrades',
      'verified': false,
      'time': '8h ago',
      'content': 'Pro tip: Diversify across different property types. My portfolio is 60% residential, 30% commercial, 10% land. Works great for risk management! 📊',
      'image': null,
      'likes': 256,
      'comments': 34,
      'shares': 21,
      'liked': false,
    },
    {
      'id': '4',
      'user': 'Emma Johnson',
      'avatar': 'https://i.pravatar.cc/150?img=9',
      'handle': '@emma_realestate',
      'verified': true,
      'time': '12h ago',
      'content': 'The Central Park Loft is now 65% funded! Only 5 days left to get in. This NYC location is prime. Don\'t miss out! 🗽',
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
      'likes': 178,
      'comments': 28,
      'shares': 15,
      'liked': false,
    },
    {
      'id': '5',
      'user': 'David Kim',
      'avatar': 'https://i.pravatar.cc/150?img=8',
      'handle': '@davidk_ada',
      'verified': false,
      'time': '1d ago',
      'content': 'Comparing traditional REITs vs Crestadel: \n\n✅ Lower entry barriers\n✅ Instant liquidity on Hydra\n✅ Full on-chain transparency\n✅ No middlemen fees\n\nThe future of real estate is here!',
      'image': null,
      'likes': 412,
      'comments': 67,
      'shares': 89,
      'liked': true,
    },
  ];

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
          'COMMUNITY',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostSheet(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF050505),
                    Color(0xFF1A0B2E),
                    Color(0xFF001F24),
                  ],
                ),
              ),
            ),
          ),
          
          // Decorative Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
              // Trending Properties Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '🔥 TRENDING PROPERTIES',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text('See All', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _trendingProperties.length,
                          itemBuilder: (context, index) => _buildTrendingPropertyCard(_trendingProperties[index]),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Tab Bar
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
                      Tab(text: 'For You'),
                      Tab(text: 'Following'),
                      Tab(text: 'Top'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildFeedList(),
                _buildFeedList(), // Same for demo
                _buildFeedList(), // Same for demo
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingPropertyCard(Map<String, dynamic> property) {
    return GestureDetector(
      onTap: () => _showPropertyDetails(property),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(property['image']),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: property['tag'] == 'HOT' ? Colors.red : (property['tag'] == 'TRENDING' ? Colors.orange : Colors.green),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      property['tag'],
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Text(property['price'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                property['name'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                property['location'],
                style: TextStyle(color: Colors.grey[300], fontSize: 12),
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: property['funded'],
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(property['funded'] * 100).toInt()}% funded', style: TextStyle(color: Colors.grey[300], fontSize: 11)),
                  Text(property['timeLeft'], style: TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) => _buildPostCard(_posts[index], index),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return GestureDetector(
      onTap: () => _showPostDetails(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration.copyWith(
          color: Colors.black.withValues(alpha: 0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(post['avatar']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post['user'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          if (post['verified'])
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified, color: Colors.blue, size: 16),
                            ),
                        ],
                      ),
                      Text(
                        '${post['handle']} • ${post['time']}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            Text(
              post['content'],
              style: TextStyle(color: Colors.grey[200], height: 1.5, fontSize: 14),
            ),
            // Image if exists
            if (post['image'] != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post['image'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[900],
                    child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Interactions
            Row(
              children: [
                _buildInteractionButton(
                  post['liked'] ? Icons.favorite : Icons.favorite_border,
                  '${post['likes']}',
                  post['liked'] ? Colors.red : Colors.grey[500]!,
                  () => setState(() => _posts[index]['liked'] = !post['liked']),
                ),
                const SizedBox(width: 24),
                _buildInteractionButton(Icons.chat_bubble_outline, '${post['comments']}', Colors.grey[500]!, () => _showPostDetails(post)),
                const SizedBox(width: 24),
                _buildInteractionButton(Icons.repeat, '${post['shares']}', Colors.grey[500]!, () {}),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.bookmark_border, color: Colors.grey[500], size: 22),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String count, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(count, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }

  void _showPropertyDetails(Map<String, dynamic> property) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(property['image'], height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: property['tag'] == 'HOT' ? Colors.red : (property['tag'] == 'TRENDING' ? Colors.orange : Colors.green),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(property['tag'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text(property['price'], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(property['name'], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(property['location'], style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Stats
                    Row(
                      children: [
                        _buildPropertyStat('Funded', '${(property['funded'] * 100).toInt()}%'),
                        _buildPropertyStat('APY', '8.5%'),
                        _buildPropertyStat('Fractions', '1,000'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Progress
                    Text('Funding Progress', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: property['funded'],
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${((property['funded'] as double) * 2400000).toStringAsFixed(0)} raised', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        Text(property['timeLeft'], style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Invest button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Invest Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showPostDetails(Map<String, dynamic> post) {
    final comments = [
      {'user': 'John Doe', 'avatar': 'https://i.pravatar.cc/150?img=3', 'text': 'Great investment choice! Tokyo real estate is booming 📈', 'time': '1h ago', 'likes': 12},
      {'user': 'Lisa Park', 'avatar': 'https://i.pravatar.cc/150?img=6', 'text': 'I got in at 85% funded. So excited for this one!', 'time': '45m ago', 'likes': 8},
      {'user': 'Marcus Johnson', 'avatar': 'https://i.pravatar.cc/150?img=7', 'text': 'What\'s the minimum investment for this property?', 'time': '30m ago', 'likes': 3},
      {'user': 'Emily Chen', 'avatar': 'https://i.pravatar.cc/150?img=10', 'text': '50 ADA minimum per fraction. Very accessible!', 'time': '25m ago', 'likes': 15},
    ];

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
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Original post
                  _buildPostCard(post, 0),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[800]),
                  const SizedBox(height: 8),
                  Text('Comments (${comments.length})', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Comments list
                  ...comments.map((comment) => _buildComment(comment)),
                ],
              ),
            ),
            // Comment input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                border: Border(top: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: AppTheme.primaryColor),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(comment['avatar']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment['user'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(comment['time'], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['text'], style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text('${comment['likes']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 16),
                    Text('Reply', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
                  ),
                  const SizedBox(width: 12),
                  const Text('Create Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Post', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your investment journey...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(icon: Icon(Icons.image, color: AppTheme.primaryColor), onPressed: () {}),
                  IconButton(icon: Icon(Icons.gif_box, color: AppTheme.primaryColor), onPressed: () {}),
                  IconButton(icon: Icon(Icons.poll, color: AppTheme.primaryColor), onPressed: () {}),
                  IconButton(icon: Icon(Icons.location_on, color: AppTheme.primaryColor), onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
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

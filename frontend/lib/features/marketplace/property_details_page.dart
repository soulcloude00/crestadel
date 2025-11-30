import 'package:flutter/material.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/features/marketplace/widgets/iframe_viewer.dart';
import 'package:provider/provider.dart';

class PropertyDetailsPage extends StatefulWidget {
  final MarketplaceListing listing;

  const PropertyDetailsPage({super.key, required this.listing});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  bool _show3DModel = false;

  void _handleBuy() {
    final walletService = context.read<WalletService>();
    if (!walletService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect your wallet first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _BuyDialog(listing: widget.listing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _show3DModel ? Icons.view_quilt : Icons.view_in_ar,
              color: Colors.white,
            ),
            tooltip: _show3DModel ? 'Show Details' : 'View 3D Model',
            onPressed: () {
              setState(() {
                _show3DModel = !_show3DModel;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
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

          if (_show3DModel) _build3DModelView() else _buildDetailsView(context),
        ],
      ),
      floatingActionButton: _show3DModel
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _show3DModel = false;
                });
              },
              label: const Text('Back to Details'),
              icon: const Icon(Icons.arrow_back),
              backgroundColor: AppTheme.primaryColor,
            )
          : FloatingActionButton.extended(
              onPressed: () {
                _handleBuy();
              },
              label: const Text('Invest Now'),
              icon: const Icon(Icons.shopping_cart),
              backgroundColor: AppTheme.primaryColor,
            ),
    );
  }

  Widget _build3DModelView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: IframeViewer(
              url:
                  'https://tinyglb.com/viewer/f2dc514cc9354c5cab0d5bb67f0b4749',
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Interactive 3D Tour',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              widget.listing.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.apartment,
                      size: 64,
                      color: Colors.white24,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Title & Location
          Text(
            widget.listing.propertyName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppTheme.primaryColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                widget.listing.location,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Key Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'APY',
                '${widget.listing.apy.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.greenAccent,
              ),
              _buildStatCard(
                'Target',
                '${(widget.listing.targetAmount / 1000).toStringAsFixed(0)}k ₳',
                Icons.flag,
                Colors.blueAccent,
              ),
              _buildStatCard(
                'Min Investment',
                '${widget.listing.pricePerFraction.toStringAsFixed(0)} ₳',
                Icons.monetization_on,
                Colors.amber,
              ),
              _buildStatCard(
                'Investors',
                '124', // Mock for now, could be dynamic
                Icons.people,
                Colors.purpleAccent,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Description
          const Text(
            'About this Property',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.listing.propertyDescription.isNotEmpty
                ? widget.listing.propertyDescription
                : 'Experience the pinnacle of luxury living with this premium real estate asset. Located in a prime district, this property offers exceptional yield potential and capital appreciation. Managed by top-tier professionals, it represents a secure and lucrative investment opportunity in the decentralized finance ecosystem.',
            style: TextStyle(color: Colors.grey[300], height: 1.6),
          ),
          const SizedBox(height: 32),

          // 3D Model Teaser
          GestureDetector(
            onTap: () {
              setState(() {
                _show3DModel = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withAlpha(128)),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withAlpha(51),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.view_in_ar,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'View 3D Model',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Explore the property in AR',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white54,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }
}

class _BuyDialog extends StatefulWidget {
  final MarketplaceListing listing;

  const _BuyDialog({super.key, required this.listing});

  @override
  State<_BuyDialog> createState() => _BuyDialogState();
}

class _BuyDialogState extends State<_BuyDialog> {
  int _quantity = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final totalCost = _quantity * widget.listing.pricePerFraction;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A0B2E),
      title: const Text(
        'Invest in Property',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How many fractions of ${widget.listing.propertyName} would you like to buy?',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.white,
                ),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                '$_quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                onPressed: _quantity < widget.listing.fractionsAvailable
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Total Cost: ${totalCost.toStringAsFixed(2)} ₳',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmPurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirm Purchase'),
        ),
      ],
    );
  }

  Future<void> _confirmPurchase() async {
    setState(() => _isLoading = true);
    try {
      final walletService = context.read<WalletService>();
      await walletService.buyFractionsReal(
        propertyId: widget.listing.id,
        amount: _quantity,
        pricePerFraction: widget.listing.pricePerFraction,
        ownerWalletAddress: widget.listing.sellerAddress,
        propertyName: widget.listing.propertyName,
        totalFractions: widget.listing.totalFractions,
        onSuccess: (propId, amount) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully purchased $amount fractions!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

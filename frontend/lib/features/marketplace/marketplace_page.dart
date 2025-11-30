import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/features/marketplace/widgets/property_card.dart';
import 'package:propfi/features/admin/admin_page.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/services/admin_service.dart';
import 'package:propfi/services/hydra_trading_service.dart';
import 'package:propfi/features/marketplace/property_details_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  bool _isLoading = false;
  String? _error;
  List<CardanoWallet> _availableWallets = [];

  // Search & Filter state
  String _searchQuery = '';
  double _minPrice = 0;
  double _maxPrice = 100000;
  String _sortBy = 'newest'; // newest, price_low, price_high, funded

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeMarketplace();
  }

  Future<void> _initializeMarketplace() async {
    // Wait a bit for wallets to inject (they load after page)
    await Future.delayed(const Duration(milliseconds: 500));

    // Check for wallets
    if (mounted) {
      final walletService = context.read<WalletService>();
      _availableWallets = await walletService.detectWallets();
      setState(() {});
    }

    // Load listings
    await _loadListings();
  }

  Future<void> _loadListings() async {
    if (!mounted) return;

    final walletService = context.read<WalletService>();
    final adminService = context.read<AdminService>();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Refresh on-chain properties first
      await adminService.refresh();

      // Pass admin's listed properties to wallet service (includes on-chain)
      final listedProperties = adminService.listedProperties;
      await walletService.fetchListings(adminProperties: listedProperties);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Filter and sort listings based on current criteria
  List<MarketplaceListing> _getFilteredListings(
    List<MarketplaceListing> listings,
  ) {
    var filtered = listings.where((listing) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!listing.propertyName.toLowerCase().contains(query) &&
            !listing.location.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Price filter
      if (listing.price < _minPrice || listing.price > _maxPrice) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'funded':
        filtered.sort(
          (a, b) => b.fundedPercentage.compareTo(a.fundedPercentage),
        );
        break;
      case 'newest':
      default:
        // Keep default order (newest)
        break;
    }

    return filtered;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        _minPrice = 0;
                        _maxPrice = 100000;
                        _sortBy = 'newest';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price Range
              const Text(
                'Price Range (ADA)',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 100000,
                divisions: 20,
                labels: RangeLabels(
                  '${_minPrice.toInt()} ₳',
                  '${_maxPrice.toInt()} ₳',
                ),
                onChanged: (values) {
                  setSheetState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_minPrice.toInt()} ₳',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    '${_maxPrice.toInt()} ₳',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sort By
              const Text(
                'Sort By',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildSortChip('Newest', 'newest', setSheetState),
                  _buildSortChip('Price: Low', 'price_low', setSheetState),
                  _buildSortChip('Price: High', 'price_high', setSheetState),
                  _buildSortChip('Most Funded', 'funded', setSheetState),
                ],
              ),
              const SizedBox(height: 24),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Refresh main page
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value, StateSetter setSheetState) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setSheetState(() => _sortBy = value);
        }
      },
      selectedColor: Colors.amber,
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
      backgroundColor: Colors.grey[800],
    );
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _minPrice > 0 ||
        _maxPrice < 100000 ||
        _sortBy != 'newest';
  }

  Future<void> _showConnectWalletDialog() async {
    final walletService = context.read<WalletService>();

    // Refresh available wallets (in case they loaded late)
    _availableWallets = walletService.getAvailableWallets();

    if (_availableWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No Cardano wallets detected. Please install Nami, Eternl, or another wallet.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      // For demo, allow simulated connection
      await _connectWallet(CardanoWallet.nami);
      return;
    }

    await showModalBottomSheet<CardanoWallet>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect Wallet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a wallet to connect',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ..._availableWallets.map(
              (wallet) => ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.amber,
                ),
                title: Text(
                  wallet.displayName,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _connectWallet(wallet);
                },
              ),
            ),
            if (_availableWallets.isEmpty)
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.amber,
                ),
                title: const Text(
                  'Nami (Demo Mode)',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _connectWallet(CardanoWallet.nami);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectWallet(CardanoWallet wallet) async {
    final walletService = context.read<WalletService>();

    final success = await walletService.connectWallet(wallet);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${wallet.displayName}'),
            backgroundColor: Colors.green,
          ),
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
  }

  void _navigateToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<WalletService, AdminService, HydraTradingService>(
      builder: (context, walletService, adminService, hydraService, child) {
        // Get filtered listings
        final filteredListings = _getFilteredListings(walletService.listings);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Marketplace'),
            actions: [
              IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: _navigateToAdmin,
                tooltip: 'Admin Panel',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadListings,
              ),
            ],
          ),
          body: Column(
            children: [
              // Header with wallet connection
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Marketplace',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    _buildWalletButton(walletService),
                  ],
                ),
              ),

              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search properties...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[500],
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _hasActiveFilters()
                            ? Colors.amber.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: _hasActiveFilters()
                            ? Border.all(color: Colors.amber)
                            : null,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: _hasActiveFilters()
                              ? Colors.amber
                              : Colors.grey[400],
                        ),
                        onPressed: _showFilterDialog,
                      ),
                    ),
                  ],
                ),
              ),

              // Active filters indicator
              if (_hasActiveFilters())
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        '${filteredListings.length} results',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                            _minPrice = 0;
                            _maxPrice = 100000;
                            _sortBy = 'newest';
                          });
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Listings
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      )
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading listings',
                              style: TextStyle(color: Colors.red[300]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadListings,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredListings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No properties found',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadListings,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: filteredListings.length,
                          itemBuilder: (context, index) {
                            final listing = filteredListings[index];

                            // Check if available in Hydra
                            final hydraFraction = hydraService
                                .getFractionForProperty(listing.id);

                            return PropertyCard(
                              title: listing.propertyName,
                              location: listing.location,
                              imageUrl: listing.imageUrl,
                              price: listing.price,
                              apy: 5.5, // Placeholder APY
                              fundedPercentage: listing.fundedPercentage,
                              fundsRaised: listing.fundsRaised,
                              targetAmount: listing.price,
                              hydraFraction: hydraFraction,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PropertyDetailsPage(listing: listing),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletButton(WalletService walletService) {
    if (walletService.status == WalletConnectionStatus.connecting) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
      );
    }

    if (walletService.isConnected) {
      return PopupMenuButton<String>(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                _truncateAddress(walletService.walletAddress ?? ''),
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'address',
            child: Row(
              children: [
                const Icon(Icons.content_copy, size: 16),
                const SizedBox(width: 8),
                Text('Copy Address'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'disconnect',
            child: Row(
              children: [
                const Icon(Icons.logout, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Disconnect', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'disconnect') {
            walletService.disconnectWallet();
          } else if (value == 'address') {
            // Copy to clipboard
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Address copied to clipboard')),
            );
          }
        },
      );
    }

    return ElevatedButton.icon(
      onPressed: _showConnectWalletDialog,
      icon: const Icon(Icons.account_balance_wallet, size: 18),
      label: const Text('Connect Wallet'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 15) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }
}

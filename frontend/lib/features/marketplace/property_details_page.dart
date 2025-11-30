import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/features/marketplace/widgets/iframe_viewer.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:convert';
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

  const _BuyDialog({required this.listing});

  @override
  State<_BuyDialog> createState() => _BuyDialogState();
}

class _BuyDialogState extends State<_BuyDialog> {
  int _currentStep = 0; // 0: Quantity, 1: KYC, 2: Confirm, 3: Certificate
  int _quantity = 1;
  bool _isLoading = false;
  
  // KYC Fields
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _idNumberController = TextEditingController();
  String _idType = 'Passport';
  bool _agreedToTerms = false;
  
  // Certificate data
  String? _certificateId;
  DateTime? _purchaseDate;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nationalityController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0B2E), Color(0xFF0D0D0D)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            // Progress indicator
            if (_currentStep < 3) _buildProgressIndicator(),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildCurrentStep(),
              ),
            ),
            // Actions
            if (_currentStep < 3) _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = ['Select Quantity', 'KYC Verification', 'Confirm Purchase', 'Certificate of Ownership'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _currentStep == 3 ? Icons.verified : Icons.real_estate_agent,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[_currentStep],
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.listing.propertyName,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          if (_currentStep < 3)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppTheme.primaryColor : Colors.grey[800],
                    border: Border.all(
                      color: isActive ? AppTheme.primaryColor : Colors.grey[700]!,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.black, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _currentStep ? AppTheme.primaryColor : Colors.grey[800],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildQuantityStep();
      case 1:
        return _buildKYCStep();
      case 2:
        return _buildConfirmStep();
      case 3:
        return _buildCertificateStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildQuantityStep() {
    final totalCost = _quantity * widget.listing.pricePerFraction;
    final minInvestment = 250.0;
    final maxPercentage = 0.5;
    final maxFractions = (widget.listing.totalFractions * maxPercentage).floor();
    
    return Column(
      children: [
        // Property preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.listing.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[900],
                    child: const Icon(Icons.home, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.listing.propertyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.listing.location, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('${widget.listing.pricePerFraction.toStringAsFixed(0)} ₳ per fraction', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Quantity selector
        Text('Select Number of Fractions', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildQuantityButton(Icons.remove, () {
              if (_quantity > 1) setState(() => _quantity--);
            }),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                '$_quantity',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            _buildQuantityButton(Icons.add, () {
              if (_quantity < widget.listing.fractionsAvailable && _quantity < maxFractions) {
                setState(() => _quantity++);
              }
            }),
          ],
        ),
        const SizedBox(height: 24),
        
        // Cost breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              _buildCostRow('Price per Fraction', '${widget.listing.pricePerFraction.toStringAsFixed(0)} ₳'),
              _buildCostRow('Quantity', '$_quantity fractions'),
              _buildCostRow('Platform Fee (1%)', '${(totalCost * 0.01).toStringAsFixed(2)} ₳'),
              const Divider(color: Colors.white24),
              _buildCostRow('Total Investment', '${(totalCost * 1.01).toStringAsFixed(2)} ₳', isTotal: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Investment limits info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Min: $minInvestment ₳ • Max: ${(maxPercentage * 100).toInt()}% of total fractions',
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.grey[400], fontSize: isTotal ? 14 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: isTotal ? AppTheme.primaryColor : Colors.white, fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildKYCStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KYC Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'KYC is required for regulatory compliance. Your data is encrypted and stored securely on-chain.',
                    style: TextStyle(color: Colors.orange[200], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Full Name
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Legal Name',
            icon: Icons.person,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          
          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              if (!v!.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Phone
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          
          // Address
          _buildTextField(
            controller: _addressController,
            label: 'Residential Address',
            icon: Icons.home,
            maxLines: 2,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          
          // Nationality
          _buildTextField(
            controller: _nationalityController,
            label: 'Nationality',
            icon: Icons.flag,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          
          // ID Type dropdown
          Text('ID Type', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: DropdownButton<String>(
              value: _idType,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A0B2E),
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white),
              items: ['Passport', 'National ID', 'Driver\'s License', 'Residence Permit']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _idType = v!),
            ),
          ),
          const SizedBox(height: 16),
          
          // ID Number
          _buildTextField(
            controller: _idNumberController,
            label: '$_idType Number',
            icon: Icons.badge,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          
          // Terms checkbox
          Row(
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                activeColor: AppTheme.primaryColor,
                side: const BorderSide(color: Colors.grey),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                  child: Text(
                    'I agree to the Terms of Service, Privacy Policy, and confirm that I am not a US person or resident of a sanctioned country.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final totalCost = _quantity * widget.listing.pricePerFraction * 1.01;
    final walletService = context.read<WalletService>();
    
    return Column(
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.2),
                Colors.purple.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.verified_user, color: AppTheme.primaryColor, size: 48),
              const SizedBox(height: 16),
              const Text('Ready to Invest', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Review your investment details', style: TextStyle(color: Colors.grey[400])),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Investment details
        _buildDetailRow('Property', widget.listing.propertyName),
        _buildDetailRow('Location', widget.listing.location),
        _buildDetailRow('Fractions', '$_quantity of ${widget.listing.totalFractions}'),
        _buildDetailRow('Ownership', '${(_quantity / widget.listing.totalFractions * 100).toStringAsFixed(2)}%'),
        _buildDetailRow('Price/Fraction', '${widget.listing.pricePerFraction.toStringAsFixed(0)} ₳'),
        _buildDetailRow('Total Cost', '${totalCost.toStringAsFixed(2)} ₳', highlight: true),
        
        const SizedBox(height: 16),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        
        // Buyer details
        Text('BUYER DETAILS', style: TextStyle(color: Colors.grey[500], fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildDetailRow('Name', _fullNameController.text),
        _buildDetailRow('Email', _emailController.text),
        _buildDetailRow('Wallet', '${walletService.walletAddress?.substring(0, 20)}...'),
        _buildDetailRow('ID Type', _idType),
        
        const SizedBox(height: 24),
        
        // Blockchain info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transaction will be recorded on Cardano blockchain via Hydra L2',
                  style: TextStyle(color: Colors.green[300], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppTheme.primaryColor : Colors.white,
              fontSize: highlight ? 15 : 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateStep() {
    final walletService = context.read<WalletService>();
    final ownershipPercentage = (_quantity / widget.listing.totalFractions * 100).toStringAsFixed(4);
    
    return Column(
      children: [
        // Certificate
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, Colors.amber, AppTheme.primaryColor],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A0B2E), Color(0xFF0D0D0D)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                // Logo & Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, color: AppTheme.primaryColor, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.primaryColor, Colors.amber],
                  ).createShader(bounds),
                  child: const Text(
                    'CERTIFICATE OF OWNERSHIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('CRESTADEL FRACTIONAL REAL ESTATE', style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 1.5)),
                
                const SizedBox(height: 20),
                Container(height: 1, color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                const SizedBox(height: 20),
                
                // Certificate ID
                Text('Certificate ID', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  _certificateId ?? 'CREST-${DateTime.now().millisecondsSinceEpoch}',
                  style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 20),
                
                // This certifies
                Text('This certifies that', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                const SizedBox(height: 8),
                Text(
                  _fullNameController.text.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('is the rightful owner of', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                
                const SizedBox(height: 16),
                
                // Fractions owned
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_quantity FRACTIONS',
                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text('($ownershipPercentage% ownership)', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                Text('of the property', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                const SizedBox(height: 8),
                Text(
                  widget.listing.propertyName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(widget.listing.location, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                
                const SizedBox(height: 20),
                Container(height: 1, color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                
                // Details grid
                Row(
                  children: [
                    Expanded(child: _buildCertDetail('Purchase Date', _formatDate(_purchaseDate ?? DateTime.now()))),
                    Expanded(child: _buildCertDetail('Total Value', '${(_quantity * widget.listing.pricePerFraction).toStringAsFixed(0)} ₳')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCertDetail('Property ID', widget.listing.id.substring(0, 8).toUpperCase())),
                    Expanded(child: _buildCertDetail('Fractions/Total', '$_quantity/${widget.listing.totalFractions}')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCertDetail('Seller', widget.listing.ownerName ?? 'Property Owner')),
                    Expanded(child: _buildCertDetail('APY', '${widget.listing.apy.toStringAsFixed(1)}%')),
                  ],
                ),
                
                const SizedBox(height: 16),
                Container(height: 1, color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                
                // Wallet addresses
                _buildCertDetail('Buyer Wallet', _truncateAddress(walletService.walletAddress ?? '')),
                const SizedBox(height: 8),
                _buildCertDetail('Seller Wallet', _truncateAddress(widget.listing.sellerAddress)),
                
                const SizedBox(height: 16),
                
                // Blockchain verification
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text('Verified on Cardano Blockchain', style: TextStyle(color: Colors.green[300], fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Actions - Updated for dApp browser compatibility
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareCertificate(),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyCertificateText(),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _downloadCertificatePdf(),
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFE53935)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_circle),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _shareCertificate() {
    final walletService = context.read<WalletService>();
    final text = _getCertificateText(walletService);
    
    // For dApp browsers - copy to clipboard and show message
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Certificate copied! You can paste and share it anywhere.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _copyCertificateText() {
    final walletService = context.read<WalletService>();
    final text = _getCertificateText(walletService);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Certificate details copied!'), backgroundColor: Colors.green),
    );
  }

  String _getCertificateText(WalletService walletService) {
    final ownershipPercentage = (_quantity / widget.listing.totalFractions * 100).toStringAsFixed(4);
    return '''
═══════════════════════════════════════
   CRESTADEL CERTIFICATE OF OWNERSHIP
═══════════════════════════════════════

Certificate ID: ${_certificateId ?? 'CREST-${DateTime.now().millisecondsSinceEpoch}'}

This certifies that:
${_fullNameController.text.toUpperCase()}

is the rightful owner of:
$_quantity FRACTIONS ($ownershipPercentage% ownership)

Property: ${widget.listing.propertyName}
Location: ${widget.listing.location}

═══════════════════════════════════════
TRANSACTION DETAILS
═══════════════════════════════════════
Purchase Date: ${_formatDate(_purchaseDate ?? DateTime.now())}
Total Value: ${(_quantity * widget.listing.pricePerFraction).toStringAsFixed(0)} ₳
Property ID: ${widget.listing.id.substring(0, 8).toUpperCase()}
Fractions: $_quantity / ${widget.listing.totalFractions}
Seller: ${widget.listing.ownerName ?? 'Property Owner'}
APY: ${widget.listing.apy.toStringAsFixed(1)}%

═══════════════════════════════════════
WALLET ADDRESSES
═══════════════════════════════════════
Buyer: ${_truncateAddress(walletService.walletAddress ?? '')}
Seller: ${_truncateAddress(widget.listing.sellerAddress)}

✓ Verified on Cardano Blockchain
═══════════════════════════════════════
''';
  }

  Future<void> _downloadCertificatePdf() async {
    final walletService = context.read<WalletService>();
    final ownershipPercentage = (_quantity / widget.listing.totalFractions * 100).toStringAsFixed(4);
    final certId = _certificateId ?? 'CREST-${DateTime.now().millisecondsSinceEpoch}';
    final purchaseDate = _formatDate(_purchaseDate ?? DateTime.now());
    final totalValue = (_quantity * widget.listing.pricePerFraction).toStringAsFixed(0);
    
    try {
      // Create PDF document
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with gold border
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('#D4AF37'), width: 3),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Center(
                        child: pw.Text(
                          'CRESTADEL',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#D4AF37'),
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Center(
                        child: pw.Text(
                          'CERTIFICATE OF OWNERSHIP',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Center(
                        child: pw.Text(
                          'Fractional Real Estate Investment',
                          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Certificate ID
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#1A1A2E'),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Certificate ID: $certId',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Owner certification
                pw.Center(
                  child: pw.Text('This certifies that', style: const pw.TextStyle(fontSize: 14)),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    _fullNameController.text.toUpperCase(),
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D4AF37')),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text('is the rightful owner of', style: const pw.TextStyle(fontSize: 14)),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    '$_quantity FRACTIONS ($ownershipPercentage% ownership)',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Property details box
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PROPERTY DETAILS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                      pw.Divider(color: PdfColors.grey400),
                      pw.SizedBox(height: 8),
                      _buildPdfRow('Property Name', widget.listing.propertyName),
                      _buildPdfRow('Location', widget.listing.location),
                      _buildPdfRow('Property ID', widget.listing.id.substring(0, 8).toUpperCase()),
                      _buildPdfRow('Total Fractions', '${widget.listing.totalFractions}'),
                      _buildPdfRow('Your Fractions', '$_quantity'),
                      _buildPdfRow('Annual Yield (APY)', '${widget.listing.apy.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Transaction details box
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TRANSACTION DETAILS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                      pw.Divider(color: PdfColors.grey400),
                      pw.SizedBox(height: 8),
                      _buildPdfRow('Purchase Date', purchaseDate),
                      _buildPdfRow('Total Value', '$totalValue ₳ (ADA)'),
                      _buildPdfRow('Seller', widget.listing.ownerName ?? 'Property Owner'),
                      _buildPdfRow('Buyer Wallet', _truncateAddress(walletService.walletAddress ?? '')),
                      _buildPdfRow('Seller Wallet', _truncateAddress(widget.listing.sellerAddress)),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Icon(const pw.IconData(0xe86c), size: 20, color: PdfColors.green),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'Verified on Cardano Blockchain',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'Generated by Crestadel • ${DateTime.now().toString().split('.')[0]}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Generate PDF bytes
      final bytes = await pdf.save();
      
      // Download in browser
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'Crestadel_Certificate_$certId.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate PDF downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCertDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _truncateAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 8)}';
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(_currentStep == 2 ? 'Confirm & Pay' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 0) {
      // Validate quantity
      final totalCost = _quantity * widget.listing.pricePerFraction;
      if (totalCost < 250) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum investment is 250 ₳'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Validate KYC
      if (!_formKey.currentState!.validate()) return;
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the terms'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      // Execute purchase
      _executePurchase();
    }
  }

  Future<void> _executePurchase() async {
    setState(() => _isLoading = true);
    String? txHash;
    try {
      final walletService = context.read<WalletService>();
      _certificateId = 'CREST-${Random().nextInt(999999).toString().padLeft(6, '0')}';
      _purchaseDate = DateTime.now();
      
      txHash = await walletService.buyFractionsReal(
        propertyId: widget.listing.id,
        amount: _quantity,
        pricePerFraction: widget.listing.pricePerFraction,
        ownerWalletAddress: widget.listing.sellerAddress,
        propertyName: widget.listing.propertyName,
        totalFractions: widget.listing.totalFractions,
        buyerName: _fullNameController.text,
        buyerEmail: _emailController.text,
        buyerPhone: _phoneController.text,
        onSuccess: (propId, amount) async {
          // Record the purchase to portfolio after tx completes
        },
      );
      
      // Record the purchase after successful transaction
      await walletService.recordPurchase(
        propertyId: widget.listing.id,
        propertyName: widget.listing.propertyName,
        location: widget.listing.location,
        imageUrl: widget.listing.imageUrl,
        fractions: _quantity,
        totalFractions: widget.listing.totalFractions,
        amount: _quantity * widget.listing.pricePerFraction,
        txHash: txHash,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 3; // Show certificate
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}

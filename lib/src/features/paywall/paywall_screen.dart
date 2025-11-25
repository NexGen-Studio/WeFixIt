import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/purchase_service.dart';
import '../../widgets/paywall_carousel.dart'; // Assuming this exists from previous steps or needs creation?
// Wait, MVP_PROGRESS said "Importe konsolidieren: widgets/paywall_carousel.dart verwenden." 
// Let's check if it exists.

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    final offerings = await PurchaseService().getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  Future<void> _buy(Package package) async {
    setState(() => _isLoading = true);
    final success = await PurchaseService().purchasePackage(package);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kauf erfolgreich! Danke für deinen Support.')),
        );
        context.pop(); // Close paywall
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    await PurchaseService().restorePurchases();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Käufe wiederhergestellt.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image or Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.blueGrey.shade900,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                
                const Spacer(),
                
                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Unlock Pro Features',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Hol dir unbegrenzte KFZ-Kosten, KI-Diagnosen und mehr!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Packages
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_offerings?.current != null && _offerings!.current!.availablePackages.isNotEmpty)
                  ..._offerings!.current!.availablePackages.map((package) => _buildPackageButton(package)).toList()
                else
                  const Text('Keine Angebote verfügbar', style: TextStyle(color: Colors.white)),
                  
                const SizedBox(height: 20),
                
                // Restore
                TextButton(
                  onPressed: _restore,
                  child: const Text(
                    'Käufe wiederherstellen',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageButton(Package package) {
    final product = package.storeProduct;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ElevatedButton(
        onPressed: () => _buy(package),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFB129), // Brand Color
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Column(
          children: [
            Text(
              product.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              product.priceString,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

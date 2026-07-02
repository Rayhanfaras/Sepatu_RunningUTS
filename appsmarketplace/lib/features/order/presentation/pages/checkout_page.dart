import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appsmarketplace/core/features/cart/presentation/providers/cart_provider.dart';
import 'package:appsmarketplace/core/routes/app_router.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _addressController = TextEditingController(text: 'Jl. Default');
  final _notesController = TextEditingController(text: '-');
  String _selectedPaymentMethod = 'dompet_kampus_global';
  List _checkoutItems = [];
  double _checkoutTotalPrice = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Cache the cart items before they get cleared upon order creation
    final cart = context.read<CartProvider>();
    _checkoutItems = List.from(cart.items);
    _checkoutTotalPrice = cart.totalPrice;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  Future<void> _handleCheckout() async {
    if (_checkoutItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang Anda kosong!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final cart = context.read<CartProvider>();
      final orderData = await cart.processCheckout(
        shippingAddress: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
      );

      final reference = orderData['reference'] as String;
      final totalPrice = (orderData['total_price'] as num).toDouble();

      if (!mounted) return;

      if (_selectedPaymentMethod == 'dompet_kampus_global') {
        // Route to PaymentPendingPage with arguments
        Navigator.pushReplacementNamed(
          context,
          AppRouter.paymentPending,
          arguments: {
            'reference': reference,
            'amount': totalPrice,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order berhasil dibuat! 🎉'), backgroundColor: Colors.green),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.dashboard, (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat order: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ITEM SUMMARY ---
                  Text(
                    'Ringkasan Pesanan',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _checkoutItems.length,
                    itemBuilder: (context, idx) {
                      final item = _checkoutItems[idx];
                      final product = item['product'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Image.network(
                            product['image_url'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image),
                          ),
                          title: Text(
                            product['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Qty: ${item['quantity']} | Size: ${item['size'] ?? 'M'}'),
                          trailing: Text(
                            'Rp ${_formatPrice(product['price'] * item['quantity'])}',
                            style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),

                  // --- SHIPPING AND NOTES ---
                  Text(
                    'Informasi Pengiriman',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Alamat Pengiriman',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Catatan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.note),
                    ),
                  ),
                  const Divider(height: 32),

                  // --- PAYMENT METHOD ---
                  Text(
                    'Pilih Metode Pembayaran',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _buildPaymentOption(
                          value: 'dompet_kampus_global',
                          title: 'Dompet Kampus Global',
                          subtitle: 'Bayar cepat menggunakan aplikasi Dompet Kampus',
                          icon: Icon(Icons.account_balance_wallet, color: cs.primary),
                        ),
                        const Divider(height: 1),
                        _buildPaymentOption(
                          value: 'cod',
                          title: 'COD (Bayar di Tempat)',
                          subtitle: 'Bayar cash saat kurir sampai',
                          icon: const Icon(Icons.handshake),
                        ),
                        const Divider(height: 1),
                        _buildPaymentOption(
                          value: 'bank_transfer',
                          title: 'Transfer Bank',
                          subtitle: 'Transfer manual via ATM/M-Banking',
                          icon: const Icon(Icons.account_balance),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- PRICING SUMMARY ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${_formatPrice(_checkoutTotalPrice)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _handleCheckout,
                      child: Text(
                        _selectedPaymentMethod == 'dompet_kampus_global'
                            ? 'Bayar Sekarang'
                            : 'Konfirmasi Pesanan',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required Widget icon,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: ListTile(
          leading: icon,
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.hintColor,
          ),
        ),
      ),
    );
  }
}

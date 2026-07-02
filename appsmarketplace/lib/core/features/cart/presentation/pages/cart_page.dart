import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appsmarketplace/core/features/cart/presentation/providers/cart_provider.dart';
import 'package:appsmarketplace/core/routes/app_router.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Map<int, String> selectedSizes = {};

  String formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (cart.items.isEmpty) {
      return const Scaffold(body: Center(child: Text("Keranjang kosong")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, i) {
                final item = cart.items[i];
                final product = item['product'];

                final sizeFromApi = item['size'] ?? "M";
                selectedSizes.putIfAbsent(item['ID'], () => sizeFromApi);

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product['image_url'],
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "Rp ${formatPrice(product['price'])}",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            DropdownButton<String>(
                              value: selectedSizes[item['ID']],
                              isExpanded: true,
                              items: ["S", "M", "L", "XL"]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) async {
                                if (val == null) return;

                                setState(() {
                                  selectedSizes[item['ID']] = val;
                                });

                                await context.read<CartProvider>().updateItem(
                                  item['ID'],
                                  item['quantity'],
                                  val,
                                );
                              },
                            ),

                            const SizedBox(height: 6),

                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    context.read<CartProvider>().updateItem(
                                      item['ID'],
                                      item['quantity'] - 1,
                                      selectedSizes[item['ID']],
                                    );
                                  },
                                ),

                                Text("${item['quantity']}"),

                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    context.read<CartProvider>().updateItem(
                                      item['ID'],
                                      item['quantity'] + 1,
                                      selectedSizes[item['ID']],
                                    );
                                  },
                                ),

                                const Spacer(),

                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    context.read<CartProvider>().removeItem(
                                      item['ID'],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 💰 TOTAL + CHECKOUT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total"),
                    Text(
                      "Rp ${formatPrice(cart.totalPrice)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                 SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.checkout);
                    },
                    child: const Text("Checkout"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

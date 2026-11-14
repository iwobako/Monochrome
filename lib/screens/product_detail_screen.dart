import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/floating_cart_button.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  final ValueListenable<int>? cartItemCount;
  final VoidCallback? onOpenCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.onAddToCart,
    this.cartItemCount,
    this.onOpenCart,
  });

  static const Color accentColor = Color(0xFFDFFF00);
  static const Color mutedColor = Color(0xFF888888);

  String formatPrice(int price) {
    final result = price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: cartItemCount == null || onOpenCart == null
          ? null
          : FloatingCartButton(
              itemCount: cartItemCount!,
              onPressed: onOpenCart!,
              heroTag: 'product-detail-cart-button',
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PRODUCT DETAIL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRODUCT PREVIEW
            _buildProductImage(),

            const SizedBox(height: 25),

            // CATEGORY & PRODUCT ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.category.toUpperCase(),
                  style: const TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'ID: ${product.id}',
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // PRODUCT NAME
            Text(
              product.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 20),

            const Divider(color: Color(0xFF292929)),

            const SizedBox(height: 20),

            // DESCRIPTION
            const Text(
              'ABOUT THIS PRODUCT',
              style: TextStyle(
                color: mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              product.description,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 14,
                height: 1.7,
              ),
            ),

            const SizedBox(height: 30),

            // PRICE SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                border: Border.all(color: const Color(0xFF303030)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL PRICE',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatPrice(product.price),
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'DIGITAL PRODUCT • ONE TIME PURCHASE',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ADD TO CART BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {
                  if (onAddToCart != null) {
                    onAddToCart!();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cart feature coming soon.'),
                        backgroundColor: Color(0xFF222222),
                      ),
                    );
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'ADD TO CART',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                'MONOCHROME® — DIGITAL GOODS STORE',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          border: Border.all(color: const Color(0xFF303030)),
        ),
        child: _buildProductImageContent(),
      ),
    );
  }

  Widget _buildProductImageContent() {
    final imagePath = product.imagePath.trim();
    if (imagePath.isEmpty) return _imagePlaceholder();

    final isNetworkImage =
        imagePath.startsWith('https://') || imagePath.startsWith('http://');

    return Image(
      image: isNetworkImage ? NetworkImage(imagePath) : AssetImage(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, color: Color(0xFF555555), size: 55),
        SizedBox(height: 12),
        Text(
          'PRODUCT PREVIEW',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'IMAGE NOT AVAILABLE',
          style: TextStyle(
            color: Color(0xFF444444),
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

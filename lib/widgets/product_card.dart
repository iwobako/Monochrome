import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  static const Color backgroundColor = Color(0xFF171717);
  static const Color accentColor = Color(0xFFDFFF00);
  static const Color mutedColor = Color(0xFF999999);

  String formatRupiah(int price) {
    final priceString = price.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < priceString.length; i++) {
      buffer.write(priceString[i]);

      final remaining = priceString.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'Rp${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAGIAN GAMBAR PRODUK
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFF222222),
                    child: _buildProductImage(),
                  ),

                  // Label digital product
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      color: accentColor,
                      child: const Text(
                        'DIGITAL GOODS',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  // Nomor ID produk
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Text(
                      product.id,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BAGIAN INFORMASI PRODUK
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    formatRupiah(product.price),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tombol detail
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'VIEW ITEM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_outward, color: accentColor, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImagePlaceholder() {
    return Container(
      color: const Color(0xFF222222),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.grid_view_rounded,
              size: 48,
              color: Color(0xFF454545),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Text(
              'MONOCHROME / ${product.category.toUpperCase()}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    final imagePath = product.imagePath.trim();
    if (imagePath.isEmpty) return buildImagePlaceholder();

    final isNetworkImage =
        imagePath.startsWith('https://') || imagePath.startsWith('http://');

    return Image(
      image: isNetworkImage ? NetworkImage(imagePath) : AssetImage(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => buildImagePlaceholder(),
    );
  }
}

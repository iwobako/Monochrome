import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FloatingCartButton extends StatelessWidget {
  final ValueListenable<int> itemCount;
  final VoidCallback onPressed;
  final String heroTag;

  const FloatingCartButton({
    super.key,
    required this.itemCount,
    required this.onPressed,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: itemCount,
      builder: (context, count, _) {
        if (count == 0) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          heroTag: heroTag,
          onPressed: onPressed,
          backgroundColor: const Color(0xFFDFFF00),
          foregroundColor: Colors.black,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: Text(
            'CART · $count',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        );
      },
    );
  }
}

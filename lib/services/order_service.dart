import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/order.dart';

class OrderService {
  static Future<OrderRecord> createOrder({
    required String userId,
    required List<CartItem> cartItems,
  }) async {
    if (cartItems.isEmpty) {
      throw ArgumentError.value(cartItems, 'cartItems', 'Cannot be empty.');
    }

    final total = cartItems.fold<int>(0, (sum, item) => sum + item.subtotal);
    final items = cartItems
        .map(
          (item) => {
            'product_id': item.product.id,
            'product_name': item.product.name,
            'product_category': item.product.category,
            'unit_price': item.product.price,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
          },
        )
        .toList();

    final row = await Supabase.instance.client
        .from('orders')
        .insert({
          'user_id': userId,
          'items': items,
          'total_amount': total,
          'payment_status': 'pending',
        })
        .select('id, user_id, items, total_amount, payment_status, created_at')
        .single();

    return OrderRecord.fromMap(Map<String, dynamic>.from(row));
  }

  static Future<List<OrderRecord>> fetchUserOrders(String userId) async {
    final rows = await Supabase.instance.client
        .from('orders')
        .select('id, user_id, items, total_amount, payment_status, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows
        .map((row) => OrderRecord.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<List<OrderRecord>> fetchAllOrders() async {
    final rows = await Supabase.instance.client
        .from('orders')
        .select('id, user_id, items, total_amount, payment_status, created_at')
        .order('created_at', ascending: false);

    return rows
        .map((row) => OrderRecord.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    if (!const ['pending', 'on_work', 'done'].contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported order status.');
    }

    await Supabase.instance.client
        .from('orders')
        .update({'payment_status': status})
        .eq('id', orderId);
  }
}

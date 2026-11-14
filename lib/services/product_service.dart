import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class ProductService {
  static Future<List<Product>> fetchActiveProducts() async {
    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select('id, name, category, description, price, image_path')
          .eq('is_active', true)
          .order('created_at');

      return rows.map((row) => Product.fromMap(row)).toList();
    } on SocketException {
      throw const FormatException(
        'No internet connection. Please check your network and try again.',
      );
    } on HttpException {
      throw const FormatException(
        'Supabase could not be reached. Please check the project URL and try again.',
      );
    } on Object catch (error) {
      final message = error.toString();
      if (message.contains('Failed host lookup') ||
          message.contains('No address associated with hostname')) {
        throw const FormatException(
          'Network lookup failed. Please check your internet connection or the Supabase URL.',
        );
      }
      if (message.contains('401') || message.contains('UNAUTHORIZED')) {
        throw const FormatException(
          'Supabase rejected the current app key. Please verify the URL and publishable key.',
        );
      }
      throw FormatException('Unable to load products right now. $message');
    }
  }
}
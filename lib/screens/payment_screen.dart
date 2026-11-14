import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/app_session.dart';
import '../services/order_service.dart';

class PaymentScreen extends StatefulWidget {
  final OrderRecord? order;
  final List<CartItem>? cartItems;
  final VoidCallback? onOrderSaved;

  const PaymentScreen.forCheckout({
    super.key,
    required this.cartItems,
    required this.onOrderSaved,
  }) : order = null,
       assert(cartItems != null),
       assert(onOrderSaved != null);

  const PaymentScreen.forOrder({super.key, required this.order})
    : assert(order != null),
      cartItems = null,
      onOrderSaved = null;

  // GANTI DENGAN DATA REKENING TOKO
  static const String bankName = 'BCA';
  static const String accountNumber = '1234567890';
  static const String accountHolder = 'MONOCHROME STORE';

  // GANTI DENGAN NOMOR WHATSAPP ADMIN
  // Format: 628xxxxxxxxxx, tanpa + atau spasi.
  static const String adminWhatsappNumber = '628XXXXXXXXXX';

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  OrderRecord? _savedOrder;
  bool _isSubmitting = false;
  bool _leftAppForWhatsApp = false;
  bool _whatsappOpened = false;

  @override
  void initState() {
    super.initState();
    _savedOrder = widget.order;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _leftAppForWhatsApp = true;
    } else if (state == AppLifecycleState.resumed &&
        _whatsappOpened &&
        _leftAppForWhatsApp) {
      _closeAfterWhatsApp();
    }
  }

  List<OrderItemRecord> get _items {
    final order = _savedOrder;
    if (order != null) return order.items;

    return widget.cartItems!
        .map(
          (item) => OrderItemRecord(
            productId: item.product.id,
            productName: item.product.name,
            productCategory: item.product.category,
            unitPrice: item.product.price.toDouble(),
            quantity: item.quantity,
            subtotal: item.subtotal.toDouble(),
          ),
        )
        .toList();
  }

  double get _totalAmount {
    final order = _savedOrder;
    if (order != null) return order.totalAmount;
    return widget.cartItems!
        .fold<int>(0, (total, item) => total + item.subtotal)
        .toDouble();
  }

  String formatPrice(num price) {
    final roundedPrice = price.round();
    return 'Rp ${roundedPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  Future<void> _copyText(BuildContext context, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));

    messenger.showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _confirmPayment() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      var order = _savedOrder;
      if (order == null) {
        final customer = AppSession.instance.user;
        if (customer == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in before confirming payment.'),
            ),
          );
          return;
        }

        order = await OrderService.createOrder(
          userId: customer.id,
          cartItems: widget.cartItems!,
        );
        if (!mounted) return;

        setState(() {
          _savedOrder = order;
        });
        widget.onOrderSaved?.call();
      }

      final productDetails = order.items
        .map((item) {
          return '- ${item.productName} x${item.quantity}';
        })
        .join('\n');

      final message =
          '''
Assalamu'alaikum Admin MONOCHROME.

Saya ingin melakukan konfirmasi pembayaran.

Order ID: ${order.id}

Produk:
$productDetails

Total pembayaran: ${formatPrice(order.totalAmount)}

Saya sudah melakukan transfer. Berikutnya saya akan mengirimkan bukti pembayaran untuk diverifikasi.

Mohon bantuannya untuk proses verifikasi dan akses produk digital.

Terima kasih.
''';

      final uri = Uri.https(
        'wa.me',
        '/${PaymentScreen.adminWhatsappNumber}',
        {'text': message},
      );
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Please try again.'),
          ),
        );
        return;
      }

      _whatsappOpened = true;
      if (_leftAppForWhatsApp &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _closeAfterWhatsApp();
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: ${error.message}')),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save the order: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _closeAfterWhatsApp() {
    _whatsappOpened = false;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        title: const Text(
          'PAYMENT',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'COMPLETE YOUR ORDER',
            style: TextStyle(
              color: Color(0xFFDFFF00),
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'PAYMENT DETAILS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // ORDER INFORMATION
          _section(
            title: 'ORDER INFORMATION',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Order ID', _savedOrder?.id ?? 'Created on confirm'),
                const SizedBox(height: 10),
                _infoRow(
                  'Status',
                  (_savedOrder?.paymentStatus ?? 'pending')
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // PURCHASED PRODUCTS
          _section(
            title: 'YOUR PURCHASE',
            child: Column(
              children: [
                ..._items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${item.quantity} × ${formatPrice(item.unitPrice)}',
                                style: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatPrice(item.subtotal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // BANK ACCOUNT
          _section(
            title: 'BANK TRANSFER',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PaymentScreen.bankName,
                  style: const TextStyle(
                    color: Color(0xFFDFFF00),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'ACCOUNT NUMBER',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        PaymentScreen.accountNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _copyText(context, PaymentScreen.accountNumber),
                      icon: const Icon(Icons.copy, color: Color(0xFFDFFF00)),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                _infoRow('Account Holder', PaymentScreen.accountHolder),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // TOTAL PAYMENT
          _section(
            title: 'TOTAL PAYMENT',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatPrice(_totalAmount),
                    style: const TextStyle(
                      color: Color(0xFFDFFF00),
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _copyText(context, _totalAmount.round().toString()),
                  icon: const Icon(Icons.copy, color: Color(0xFFDFFF00)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // PAYMENT RULES
          _section(
            title: 'PAYMENT RULES',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Rule(text: 'Transfer harus sesuai nominal yang tertera.'),
                _Rule(
                  text: 'Tidak boleh ada kesalahan atau perubahan nominal.',
                ),
                _Rule(text: 'Pastikan rekening tujuan sudah benar.'),
                _Rule(text: 'Simpan bukti transfer untuk proses verifikasi.'),
                _Rule(
                  text:
                      'Pesanan diproses setelah pembayaran diverifikasi admin.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // DIGITAL ACCESS INFORMATION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF303030)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFFDFFF00)),
                    SizedBox(width: 10),
                    Text(
                      'DIGITAL ACCESS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Link Google Drive dan password produk akan diberikan oleh admin setelah pembayaran berhasil diverifikasi.',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // WHATSAPP BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _confirmPayment,
              icon: const Icon(Icons.chat),
              label: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'CONFIRM VIA WHATSAPP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDFFF00),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'MONOCHROME DIGITAL STORE',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  final String text;

  const _Rule({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFDFFF00))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/app_session.dart';
import '../services/order_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color accentColor = Color(0xFFDFFF00);

  late Future<List<OrderRecord>> _ordersFuture;
  final Set<String> _updatingOrderIds = {};

  @override
  void initState() {
    super.initState();
    _ordersFuture = OrderService.fetchAllOrders();
  }

  void _reloadOrders() {
    setState(() {
      _ordersFuture = OrderService.fetchAllOrders();
    });
  }

  Future<void> _updateStatus(OrderRecord order, String status) async {
    setState(() {
      _updatingOrderIds.add(order.id);
    });

    try {
      await OrderService.updateOrderStatus(orderId: order.id, status: status);
      if (!mounted) return;
      _reloadOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${_statusLabel(status)}.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update order status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingOrderIds.remove(order.id);
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await AppSession.instance.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not sign out: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = AppSession.instance.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        title: const Text(
          'ADMIN DASHBOARD',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _reloadOrders,
            tooltip: 'Refresh orders',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _signOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<OrderRecord>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error);
          }

          final orders = snapshot.data ?? [];
          return RefreshIndicator(
            color: accentColor,
            backgroundColor: const Color(0xFF171717),
            onRefresh: () async {
              final future = OrderService.fetchAllOrders();
              setState(() {
                _ordersFuture = future;
              });
              await future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _buildWelcome(admin?.name ?? 'Admin'),
                const SizedBox(height: 18),
                if (orders.isEmpty)
                  _buildSummary(const [])
                else
                  _buildSummary(orders),
                const SizedBox(height: 26),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ALL ORDERS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      '${orders.length} TOTAL',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (orders.isEmpty)
                  _buildEmptyState()
                else
                  ...orders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AdminOrderCard(
                        order: order,
                        isUpdating: _updatingOrderIds.contains(order.id),
                        onStatusChanged: (status) =>
                            _updateStatus(order, status),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcome(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            color: accentColor,
            alignment: Alignment.center,
            child: const Icon(Icons.admin_panel_settings, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STORE OVERVIEW',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Welcome, $name',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<OrderRecord> orders) {
    final pendingCount = orders
        .where((order) => order.paymentStatus == 'pending')
        .length;
    final workCount = orders
        .where((order) => order.paymentStatus == 'on_work')
        .length;
    final doneCount = orders
        .where((order) => order.paymentStatus == 'done')
        .length;
    final total = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'ORDERS',
                value: '${orders.length}',
                icon: Icons.receipt_long,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'PENDING',
                value: '$pendingCount',
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'ON WORK',
                value: '$workCount',
                icon: Icons.autorenew,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'DONE',
                value: '$doneCount',
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          label: 'ORDER VALUE',
          value: _formatPrice(total),
          icon: Icons.payments_outlined,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: accentColor, size: 44),
            const SizedBox(height: 14),
            const Text(
              'COULD NOT LOAD ORDERS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF999999)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _reloadOrders,
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, color: Color(0xFF777777), size: 36),
          SizedBox(height: 10),
          Text(
            'NO ORDERS YET',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isWide;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFDFFF00), size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
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

class _AdminOrderCard extends StatelessWidget {
  final OrderRecord order;
  final bool isUpdating;
  final ValueChanged<String> onStatusChanged;

  const _AdminOrderCard({
    required this.order,
    required this.isUpdating,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentStatus = _statusesFor(order.paymentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(color: Color(0xFF888888), fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'CUSTOMER  ${order.userId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 9,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity} × ${item.productName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    _formatPrice(item.subtotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: Color(0xFF303030)),
          Row(
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                _formatPrice(order.totalAmount),
                style: const TextStyle(
                  color: Color(0xFFDFFF00),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'STATUS',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (isUpdating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFDFFF00),
                  ),
                )
              else
                DropdownButton<String>(
                  value: order.paymentStatus,
                  dropdownColor: const Color(0xFF222222),
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  items: currentStatus
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (status) {
                    if (status != null && status != order.paymentStatus) {
                      onStatusChanged(status);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _statusesFor(String current) {
    const statuses = ['pending', 'on_work', 'done'];
    if (statuses.contains(current)) return statuses;
    return [...statuses, current];
  }
}

String _statusLabel(String status) {
  return status
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String _formatDate(DateTime value) {
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String _formatPrice(num amount) {
  final formatted = amount.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return 'Rp $formatted';
}

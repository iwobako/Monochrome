import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../services/app_session.dart';
import '../services/product_service.dart';
import '../widgets/category_filter.dart';
import '../widgets/floating_cart_button.dart';
import '../widgets/product_card.dart';
import '../screens/product_detail_screen.dart';
import '../models/cart_item.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color backgroundColor = Color(0xFF0A0A0A);
  static const Color surfaceColor = Color(0xFF171717);
  static const Color accentColor = Color(0xFFDFFF00);
  static const Color mutedColor = Color(0xFF999999);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Product>> _productsFuture;

  final List<String> _categories = const [
    'All',
    'Templates',
    'Presets',
    'Files',
  ];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final List<CartItem> _cartItems = [];
  final ValueNotifier<int> _cartItemCount = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService.fetchActiveProducts();
  }

  List<Product> _filteredProducts(List<Product> products) {
    return products.where((product) {
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;

      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.id.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cartItemCount.dispose();
    super.dispose();
  }

  void _updateCartItemCount() {
    _cartItemCount.value = _cartItems.fold(
      0,
      (total, item) => total + item.quantity,
    );
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _reloadProducts() {
    setState(() {
      _productsFuture = ProductService.fetchActiveProducts();
    });
  }

  void _showProductMessage(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: product,
          onAddToCart: () => _addToCart(product),
          cartItemCount: _cartItemCount,
          onOpenCart: _openCart,
        ),
      ),
    );
  }

  Future<void> _openOrderHistory() async {
    if (!await _ensureSignedIn() || !mounted) return;

    final user = AppSession.instance.user;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderHistoryScreen(userId: user.id)),
    );
  }

  Future<bool> _ensureSignedIn() async {
    if (AppSession.instance.isActive) return true;

    return await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ) ??
        false;
  }

  Future<void> _addToCart(Product product) async {
    if (!await _ensureSignedIn() || !mounted) return;

    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (index >= 0) {
        _cartItems[index].quantity++;
      } else {
        _cartItems.add(CartItem(product: product));
      }
      _updateCartItemCount();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: const Color(0xFF222222),
      ),
    );
  }

  void _increaseCartItem(String productId) {
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == productId,
      );

      if (index >= 0) {
        _cartItems[index].quantity++;
        _updateCartItemCount();
      }
    });
  }

  void _decreaseCartItem(String productId) {
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == productId,
      );

      if (index >= 0) {
        if (_cartItems[index].quantity > 1) {
          _cartItems[index].quantity--;
        } else {
          _cartItems.removeAt(index);
        }
        _updateCartItemCount();
      }
    });
  }

  void _removeCartItem(String productId) {
    setState(() {
      _cartItems.removeWhere((item) => item.product.id == productId);
      _updateCartItemCount();
    });
  }

  Future<void> _openCart() async {
    if (!await _ensureSignedIn() || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cartItems: _cartItems,
          onIncrease: _increaseCartItem,
          onDecrease: _decreaseCartItem,
          onRemove: _removeCartItem,
          onCheckout: () {
            setState(() {
              _cartItems.clear();
              _updateCartItemCount();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order placed successfully.')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: _buildDrawer(),
      floatingActionButton: FloatingCartButton(
        itemCount: _cartItemCount,
        onPressed: _openCart,
        heroTag: 'home-cart-button',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  final products = _filteredProducts(snapshot.data ?? []);

                  return CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeroSection()),
                      SliverToBoxAdapter(child: _buildSearchField()),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: CategoryFilter(
                            categories: _categories,
                            selectedCategory: _selectedCategory,
                            onCategorySelected: _selectCategory,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildCatalogHeading(products.length),
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFDFFF00),
                            ),
                          ),
                        )
                      else if (snapshot.hasError)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildProductLoadError(snapshot.error),
                        )
                      else if (products.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.52,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final product = products[index];

                              return ProductCard(
                                product: product,
                                onTap: () => _showProductMessage(product),
                              );
                            }, childCount: products.length),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF292929), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            color: accentColor,
            alignment: Alignment.center,
            child: const Text(
              'M',
              style: TextStyle(
                color: Colors.black,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONOCHROME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'DIGITAL GOODS DEPARTMENT',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 8,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // MENU BUTTON
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DRAWER
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF101010),
      width: 290,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BRAND HEADER
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    color: accentColor,
                    alignment: Alignment.center,
                    child: const Text(
                      'M',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONOCHROME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'DIGITAL GOODS DEPARTMENT',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF292929)),

            _buildAccountSection(),

            const Divider(color: Color(0xFF292929)),

            // NAVIGATION LABEL
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text(
                'NAVIGATION / 01',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // MENU ITEMS
            _drawerItem(
              icon: Icons.home_outlined,
              title: 'HOME',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            _drawerItem(
              icon: Icons.shopping_bag_outlined,
              title: 'MY CART',
              onTap: () {
                Navigator.pop(context);
                _openCart();
              },
            ),

            _drawerItem(
              icon: Icons.receipt_long_outlined,
              title: 'ORDER HISTORY',
              onTap: () {
                Navigator.pop(context);
                _openOrderHistory();
              },
            ),

            const Spacer(),

            // FOOTER
            const Divider(color: Color(0xFF292929)),

            const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONOCHROME®',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'DIGITAL GOODS DEPARTMENT',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'V.1.0.0',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
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

  // DRAWER ITEM
  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: mutedColor, size: 19),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white38,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return AnimatedBuilder(
      animation: AppSession.instance,
      builder: (context, _) {
        final user = AppSession.instance.user;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: user == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, color: accentColor, size: 13),
                        SizedBox(width: 7),
                        Text(
                          'ACCESS REQUIRED',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'YOUR SPACE.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Sign in to access your digital collection.',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    const SizedBox(height: 18),
                    _authButton(
                      title: 'LOGIN',
                      isPrimary: true,
                      onTap: _openLogin,
                    ),
                    const SizedBox(height: 9),
                    _authButton(
                      title: 'REGISTER',
                      isPrimary: false,
                      onTap: _openRegister,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_open_outlined,
                          color: accentColor,
                          size: 13,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          user.isAdmin
                              ? 'ACTIVE ADMIN SESSION'
                              : 'ACTIVE ACCOUNT SESSION',
                          style: const TextStyle(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'YOUR SPACE.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${user.name}\n${user.email}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _authButton(
                      title: 'SIGN OUT',
                      isPrimary: false,
                      onTap: _signOut,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _authButton({
    required String title,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: ValueKey('auth_$title'),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? accentColor : const Color(0xFF171717),
          foregroundColor: isPrimary ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF303030)),
          ),
        ),
        child: Text(title),
      ),
    );
  }

  void _openLogin() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openRegister() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  Future<void> _signOut() async {
    try {
      await AppSession.instance.signOut();
      if (mounted) Navigator.pop(context);
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not sign out: ${error.message ?? error.code}'),
            backgroundColor: surfaceColor,
          ),
        );
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not sign out: $error'),
            backgroundColor: surfaceColor,
          ),
        );
      }
    }
  }

  // HERO / BANNER
  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border.all(color: const Color(0xFF303030)),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -4,
              top: -15,
              child: Text(
                'M/',
                style: TextStyle(
                  color: Color(0xFF252525),
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  color: accentColor,
                  child: const Text(
                    'INDEPENDENT DIGITAL STORE',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'DESIGN YOUR\nOWN RULES.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 0.98,
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 14),

                const SizedBox(
                  width: 250,
                  child: Text(
                    'Templates, presets, and digital assets '
                    'for your next creative project.',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Row(
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: accentColor,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'EXPLORE THE COLLECTION',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // SEARCH
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(color: Colors.white, fontSize: 13),
        cursorColor: accentColor,
        decoration: InputDecoration(
          hintText: 'Search products, presets, files...',
          hintStyle: const TextStyle(color: Color(0xFF777777), fontSize: 12),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: mutedColor,
            size: 21,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: mutedColor,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF303030)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: accentColor),
          ),
        ),
      ),
    );
  }

  // CATALOG HEADING
  Widget _buildCatalogHeading(int productCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THE COLLECTION',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _selectedCategory == 'All'
                      ? 'ALL PRODUCTS'
                      : _selectedCategory.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'ITEMS FOUND',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                productCount.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductLoadError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'COULD NOT LOAD PRODUCTS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error is Exception
                  ? error
                        .toString()
                        .replaceFirst('FormatException: ', '')
                        .replaceFirst('Exception: ', '')
                  : '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: mutedColor, height: 1.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: _reloadProducts,
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: const BorderSide(color: accentColor),
              ),
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }

  // EMPTY SEARCH RESULT
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF555555),
              size: 48,
            ),

            const SizedBox(height: 16),

            const Text(
              'NO ITEMS FOUND',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Try another keyword or choose a different category.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor, fontSize: 12, height: 1.5),
            ),

            const SizedBox(height: 18),

            OutlinedButton(
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: const BorderSide(color: accentColor),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('RESET FILTERS'),
            ),
          ],
        ),
      ),
    );
  }

  // BOTTOM BAR
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF292929))),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt_rounded, color: accentColor, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'DIGITAL GOODS. INSTANT CREATIVITY.',
              style: TextStyle(
                color: mutedColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Text(
            'MONO / 001',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

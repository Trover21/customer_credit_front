import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/hover_widget.dart';
import 'customer_list_screen.dart';
import '../screens/recycle_bin_screen.dart';
import 'manage_users_screen.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with TickerProviderStateMixin {
  String _activeSection = 'dashboard';
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  String? _hoveredSection;
  String _role = '';


  @override
  void initState() {
    super.initState();
    _loadRole();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final role = await AuthService().getRole();
    if (mounted) {
      setState(() {
        _role = role ?? '';
      });
    }
  }

  void _toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ናብ ደገ ክትወጽእ ዲኻ?'),
        content: const Text('ርግጸኛ ዲኻ ካብ Acount ክትወጽእ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ኣይፋል'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kCoral500),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('እወ፣ ውጻእ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await AuthService().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 1000;
    final theme = Theme.of(context);

    Widget bodyContent;
    switch (_activeSection) {
      case 'customers':
        bodyContent = const CustomerListScreen();
        break;
      case 'recycle_bin':
        bodyContent = const RecycleBinScreen();
        break;
      case 'about':
        bodyContent = _buildAboutDeveloperPage(context);
        break;
      case 'manage_users':
        bodyContent = const ManageUsersScreen();
        break;
      case 'dashboard':
      default:
        bodyContent = _buildSupermarketDashboard(context);
        break;
    }

    // ─── AKU Logo ───────────────────────────────────────────────────
    Widget logoWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AKU animated logo box
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (ctx, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          ),
          child: Image.asset(
            'assets/images/image.png',
            width: 60,
            height: 70,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "AKU Supermarket",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );

    // ─── Sidebar Items ───────────────────────────────────────────────
    List<Widget> sidebarItems = [
      _buildSidebarItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        title: "Dashboard",
        sectionKey: 'dashboard',
        context: context,
      ),
      _buildSidebarItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        title: "Customers",
        sectionKey: 'customers',
        context: context,
      ),
      if (_role == 'admin')
        _buildSidebarItem(
          icon: Icons.manage_accounts_outlined,
          activeIcon: Icons.manage_accounts,
          title: "Manage Users",
          sectionKey: 'manage_users',
          context: context,
        ),
      // Recycle Bin for deleted customers
      _buildSidebarItem(
        icon: Icons.delete_outline,
        activeIcon: Icons.delete,
        title: "Recycle Bin",
        sectionKey: 'recycle_bin',
        context: context,
      ),
      
      _buildSidebarItem(
        icon: Icons.info_outline,
        activeIcon: Icons.info,
        title: "About Developer",
        sectionKey: 'about',
        context: context,
      ),
      const Divider(height: 32, color: Colors.transparent),
      // Theme toggle button
      ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, __) {
          final dark = mode == ThemeMode.dark;
          return ListTile(
            leading: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: kPrimaryGreen,
            ),
            title: Text(
              dark ? "Light Mode" : "Dark Mode",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: _toggleTheme,
          );
        },
      ),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            // ── Fixed Left Sidebar ──────────────────────────────────
            Container(
              width: 255,
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  right: BorderSide(color: theme.dividerColor, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 28.0, horizontal: 20.0),
                    child: logoWidget,
                  ),
                  const Divider(color: Colors.transparent),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: sidebarItems,
                    ),
                  ),
                  // Kidoo Logo at bottom of sidebar
                  _buildKidooLogo(theme),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "v1.0.0 © 2026",
                      style: TextStyle(color: kSlate500, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            // ── Right Content ───────────────────────────────────────
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  toolbarHeight: 70,
                  title: Text(
                    _activeSection == 'dashboard'
                        ? 'AKU Super-Market — Dashboard'
                        : (_activeSection == 'customers'
                            ? 'Customer Credit Register'
                            : (_activeSection == 'manage_users'
                                ? 'Manage Users'
                                : (_activeSection == 'recycle_bin'
                                    ? 'Recycle Bin'
                                    : 'About Developer'))),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  actions: [
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeNotifier,
                      builder: (_, mode, __) => IconButton(
                        tooltip: mode == ThemeMode.dark
                            ? 'Switch to Light Mode'
                            : 'Switch to Dark Mode',
                        icon: Icon(
                          mode == ThemeMode.dark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        onPressed: _toggleTheme,
                      ),
                    ),
                    IconButton(
                      tooltip: 'ናብ ደገ ውጻእ (Logout)',
                      icon: const Icon(Icons.logout_rounded, color: kAmber500),
                      onPressed: _confirmLogout,
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
                body: bodyContent,
              ),
            ),
          ],
        ),
      );
    } else {
      // ── Mobile Drawer Layout ────────────────────────────────────────
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 65,
          title: Text(
            _activeSection == 'dashboard'
                ? 'AKU Super-Market'
                : (_activeSection == 'customers'
                    ? 'Customer Credit'
                    : (_activeSection == 'manage_users' ? 'Manage Users' : 'About Developer')),
          ),
          actions: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) => IconButton(
                icon: Icon(
                    mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleTheme,
              ),
            ),
            IconButton(
              tooltip: 'ናብ ደገ ውጻእ (Logout)',
              icon: const Icon(Icons.logout_rounded, color: kAmber500),
              onPressed: _confirmLogout,
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                      bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Center(child: logoWidget),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  children: sidebarItems,
                ),
              ),
              _buildKidooLogo(theme),
              const SizedBox(height: 12),
            ],
          ),
        ),
        body: bodyContent,
      );
    }
  }

  // ── Kidoo Logo Widget ──────────────────────────────────────────────
  Widget _buildKidooLogo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withAlpha(102),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // K badge
            _kidooBadge('K', const Color(0xFF10B981)),
            const SizedBox(width: 8),
            // T badge
            _kidooBadge('T', const Color(0xFF3B82F6)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Kidoo Tech',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Kidoo Software Tech',
                    style: TextStyle(
                      color: Color(0xFFB0C4DE),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
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

  Widget _kidooBadge(String letter, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: kAmber500.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingImage(String assetPath, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(31),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(assetPath, fit: BoxFit.cover),
      ),
    );
  }

  // ── Sidebar Menu Item ──────────────────────────────────────────────
  Widget _buildSidebarItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required String sectionKey,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isSelected = _activeSection == sectionKey;
    final bool isWide = MediaQuery.of(context).size.width > 850;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredSection = sectionKey),
        onExit: (_) => setState(() => _hoveredSection = null),
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: _hoveredSection == sectionKey ? kPrimaryGreen.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            selected: isSelected,
            selectedTileColor: kPrimaryGreen.withAlpha(31),
            selectedColor: kPrimaryGreen,
            iconColor: kSlate500,
            textColor: theme.textTheme.bodyLarge?.color?.withAlpha(179),
            leading: Icon(isSelected ? activeIcon : icon, size: 22),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              setState(() => _activeSection = sectionKey);
              if (!isWide) Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  // ── Supermarket Dashboard ──────────────────────────────────────────
  Widget _buildSupermarketDashboard(BuildContext context) {
    final theme = Theme.of(context);

    // All products — 'image' uses Image.asset, 'emoji' is fallback
    final List<Map<String, dynamic>> products = [
      {'name': 'Tomato',         'image': 'assets/images/tomato.png',   'unit': '1 kg',    'price': 85.0,  'color': const Color(0xFFFF6B6B)},
      {'name': 'Sugar',          'image': 'assets/images/sugar.png',    'unit': '1 kg',    'price': 120.0, 'color': const Color(0xFFFAD7A0)},
      {'name': 'Potato',         'image': 'assets/images/potato.png',    'unit': '1 kg',    'price': 60.0,  'color': const Color(0xFFD4A574)},
      {'name': 'Lentils',        'image': 'assets/images/lentils.png',   'unit': '1 kg',    'price': 145.0, 'color': const Color(0xFFE67E22)},
      {'name': 'Pasta',          'image': 'assets/images/pasta.png',    'unit': '500 g',   'price': 55.0,  'color': const Color(0xFFF7DC6F)},
      {'name': 'Macaroni',       'image': 'assets/images/macaroni.png', 'unit': '400 g',   'price': 48.0,  'color': const Color(0xFFF0E68C)},
      {'name': 'Curry Spice',    'image': 'assets/images/curry_spice.png','unit': '100 g',  'price': 70.0,  'color': const Color(0xFFFF8C00)},
      {'name': 'Soap (Fesasi)',  'image': 'assets/images/soap.png',     'unit': '1 pc',    'price': 35.0,  'color': const Color(0xFF87CEEB)},
      {'name': 'Injera',         'image': 'assets/images/injera.png',   'unit': '1 pack',  'price': 25.0,  'color': const Color(0xFFDEB887)},
      {'name': 'Sossi Mince',    'image': 'assets/images/sossi.png',    'unit': '400 g',   'price': 55.0,  'color': const Color(0xFFE8A87C)},
      {'name': 'Coca-Cola',      'image': 'assets/images/cocacola.png', 'unit': '500 ml',  'price': 45.0,  'color': const Color(0xFFE53935)},
      {'name': 'Sunflower Oil',  'image': 'assets/images/sunflower_oil.png','unit': '5 L',  'price': 580.0, 'color': const Color(0xFFFDD835)},
      {'name': 'Bread (Dabo)',   'emoji': '🍞',                          'unit': '1 pc',    'price': 22.0,  'color': const Color(0xFFD7A05A)},
      {'name': 'Awash Wine',     'image': 'assets/images/awash_wine.png','unit': '750 ml',  'price': 280.0, 'color': const Color(0xFF800020)},
      {'name': 'Water (Kaliot)', 'emoji': '💧',                          'unit': '1.5 L',   'price': 18.0,  'color': const Color(0xFF4FC3F7)},
      {'name': 'Eggs (Enkutat)', 'emoji': '🥚',                          'unit': '12 pcs',  'price': 120.0, 'color': const Color(0xFFFFF9C4)},
      {'name': 'Chicken (Doro)', 'emoji': '🍗',                          'unit': '1 kg',    'price': 320.0, 'color': const Color(0xFFFFCC80)},
      {'name': 'Laundry Det.',   'emoji': '🧺',                          'unit': '1 kg',    'price': 95.0,  'color': const Color(0xFF81D4FA)},
    ];

    final List<Map<String, dynamic>> categories = [
      {'name': 'Grocery', 'icon': Icons.shopping_basket_outlined},
      {'name': 'Beverages', 'icon': Icons.local_bar_outlined},
      {'name': 'Household', 'icon': Icons.home_outlined},
      {'name': 'Bakery', 'icon': Icons.bakery_dining_outlined},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Banner ──────────────────────────────────────────
          _buildHeroBanner(context),
          const SizedBox(height: 24),

          // ── Categories ──────────────────────────────────────────
          Text(
            "Categories",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: categories
                .map((c) => _buildCategoryItem(c['name'], c['icon'], theme))
                .toList(),
          ),
          const SizedBox(height: 28),

          // ── Products Header ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Our Products",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGreen.withAlpha(128),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "All Items",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Product Grid ─────────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 900
                  ? 4
                  : MediaQuery.of(context).size.width > 600
                      ? 3
                      : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, i) => _buildProductCard(
              products[i],
              theme,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Hero Banner with floating animation ───────────────────────────
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B589), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryGreen.withAlpha(64),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(13),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(18),
              ),
            ),
          ),
          // Content
          Row(
            children: [
              // Left text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AKU SUPER-MARKET",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Credit & Payment Management System",
                      style: TextStyle(
                        color: Colors.white.withAlpha(217),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Manage Customers →",
                        style: TextStyle(
                          color: kPrimaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Floating image cluster
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildFloatingImage('assets/images/tomato.png', 40),
                        const SizedBox(width: 8),
                        _buildFloatingImage('assets/images/potato.png', 36),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFloatingImage('assets/images/soap.png', 34),
                        const SizedBox(width: 8),
                        _buildFloatingImage('assets/images/cocacola.png', 38),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Category Item ─────────────────────────────────────────────────
  Widget _buildCategoryItem(String name, IconData icon, ThemeData theme) {
    return HoverWidget(
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: kPrimaryGreen.withAlpha(26),
              shape: BoxShape.circle,
              border: Border.all(
                color: kPrimaryGreen.withAlpha(51),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: kPrimaryGreen, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Product Card ─────────────────────────────────────────────────
  Widget _buildProductCard(Map<String, dynamic> p, ThemeData theme) {
    final Color cardColor = (p['color'] as Color);
    final bool hasImage = p.containsKey('image');

    return HoverWidget(
      child: Card(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.dividerColor, width: 1),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image area — real photo OR emoji
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? Image.asset(
                          p['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              '🛒',
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        )
                      : Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor.withAlpha(38),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              p['emoji'] as String,
                              style: const TextStyle(fontSize: 42),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              // Name
              Text(
                p['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Unit badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cardColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p['unit'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cardColor.withAlpha(230),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Add button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: kPrimaryGreen,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryGreen.withAlpha(77),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── About Developer Page ─────────────────────────────────────────
  Widget _buildAboutDeveloperPage(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            color: theme.cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: theme.dividerColor, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimaryGreen, Color(0xFF10B981)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryGreen.withAlpha(77),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "About Developer",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "AKU Super-Market Credit System Developer",
                    style: TextStyle(color: kSlate500, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildContactRow(
                    icon: Icons.email_outlined,
                    label: "Email",
                    value: "zemakidoo2015@gmail.com",
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _buildContactRow(
                    icon: Icons.phone_outlined,
                    label: "Phone",
                    value: "0900413372",
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _buildContactRow(
                    icon: Icons.location_on_outlined,
                    label: "Address",
                    value: "Mekelle, Zone 17",
                    theme: theme,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    "AKU Super-Market — Premium Credit Management",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: kSlate500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryGreen.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kPrimaryGreen, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: kSlate500,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

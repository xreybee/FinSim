import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/finance_controller.dart';
import '../controllers/theme_controller.dart';
import 'widgets/glassmorphism_widgets.dart';
import 'tabs/overview_tab.dart';
import 'tabs/budget_tab.dart';
import 'tabs/goals_tab.dart';
import 'tabs/transactions_tab.dart';
import 'tabs/reports_tab.dart';
import 'profile_page.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;

  ImageProvider? _getProfileImageProvider(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image/')) {
      final base64Str = photoUrl.split(',').last;
      try {
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        return null;
      }
    }
    if (kIsWeb || photoUrl.startsWith('http://') || photoUrl.startsWith('https://') || photoUrl.startsWith('blob:')) {
      return NetworkImage(photoUrl);
    }
    final file = File(photoUrl);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  final List<Widget> _pages = const [
    OverviewTab(),
    BudgetTab(),
    GoalsTab(),
    TransactionsTab(),
    ReportsTab(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Ringkasan', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard},
    {'title': 'Pos Anggaran', 'icon': Icons.pie_chart_outline, 'activeIcon': Icons.pie_chart},
    {'title': 'Impian', 'icon': Icons.stars_outlined, 'activeIcon': Icons.stars},
    {'title': 'Transaksi', 'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long},
    {'title': 'Ekspor Laporan', 'icon': Icons.file_download_outlined, 'activeIcon': Icons.file_download},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      if (auth.currentUserId != null) {
        Provider.of<FinanceController>(context, listen: false).init(auth.currentUserId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return _buildMobileLayout();
    } else if (width < 1000) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  // --- TABLET LAYOUT (Navigation Rail) ---
  Widget _buildTabletLayout() {
    final auth = Provider.of<AuthController>(context);
    final finance = Provider.of<FinanceController>(context);
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = themeCtrl.isDarkMode;

    final railBg = isDark ? const Color(0x0F000000) : const Color(0x0A000000);
    final railBorderColor = isDark ? const Color(0x22FFFFFF) : const Color(0x18000000);
    final divColor = isDark ? Colors.white12 : Colors.black12;
    final brandColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      body: BubbleBackground(
        child: Row(
          children: [
            Container(
              width: 82,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: railBorderColor, width: 1.5),
                ),
              ),
              child: GlassCard(
                borderRadius: 0.0,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                backgroundColor: railBg,
                child: Column(
                  children: [
                    Text(
                      'fs',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: brandColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Divider(color: divColor, height: 32),

                    Expanded(
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        backgroundColor: Colors.transparent,
                        selectedIconTheme: const IconThemeData(color: Color(0xFF00BFA5), size: 24),
                        unselectedIconTheme: IconThemeData(color: isDark ? Colors.white60 : const Color(0xFF78909C), size: 22),
                        labelType: NavigationRailLabelType.none,
                        destinations: _menuItems.map((item) {
                          return NavigationRailDestination(
                            icon: Icon(item['icon']),
                            selectedIcon: Icon(item['activeIcon']),
                            label: Text(item['title']),
                          );
                        }).toList(),
                      ),
                    ),

                    Divider(color: divColor, height: 24),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      onPressed: () async {
                        finance.clear();
                        await auth.signOut();
                      },
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  _buildDesktopTopBar(),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT (Bottom Navigation Bar) ---
  Widget _buildMobileLayout() {
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = themeCtrl.isDarkMode;

    final navBg = isDark ? const Color(0x1A000000) : const Color(0x33FFFFFF);
    final navBorder = isDark ? const Color(0x33FFFFFF) : const Color(0x18000000);
    final unselectedColor = isDark ? Colors.white60 : const Color(0xFF78909C);

    return Scaffold(
      body: BubbleBackground(
        child: Column(
          children: [
            _buildAppBarHeader(),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            top: BorderSide(color: navBorder, width: 1.0),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: navBg,
              selectedItemColor: const Color(0xFF00BFA5),
              unselectedItemColor: unselectedColor,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
              items: _menuItems.map((item) {
                return BottomNavigationBarItem(
                  icon: Icon(item['icon']),
                  activeIcon: Icon(item['activeIcon']),
                  label: item['title'],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // --- DESKTOP LAYOUT (Left Sidebar Menu) ---
  Widget _buildDesktopLayout() {
    final auth = Provider.of<AuthController>(context);
    final finance = Provider.of<FinanceController>(context);
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = themeCtrl.isDarkMode;

    final sidebarBg = isDark ? const Color(0x0F000000) : const Color(0x0A000000);
    final sidebarBorder = isDark ? const Color(0x22FFFFFF) : const Color(0x18000000);
    final divColor = isDark ? Colors.white12 : Colors.black12;
    final brandColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final nameColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white54 : const Color(0xFF78909C);
    final menuItemColor = isDark ? Colors.white70 : const Color(0xFF546E7A);

    return Scaffold(
      body: BubbleBackground(
        child: Row(
          children: [
            Container(
              width: 280,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: sidebarBorder, width: 1.5),
                ),
              ),
              child: GlassCard(
                borderRadius: 0.0,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                backgroundColor: sidebarBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'finsim',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: brandColor,
                          letterSpacing: 2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Divider(color: divColor, height: 24),

                    // User Profile Brief
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfilePage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF00BFA5).withOpacity(0.15),
                              backgroundImage: _getProfileImageProvider(finance.userProfile?.photoUrl ?? ''),
                              child: _getProfileImageProvider(finance.userProfile?.photoUrl ?? '') != null
                                  ? null
                                  : const Icon(Icons.person, color: Color(0xFF00BFA5), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    finance.userProfile?.name.isNotEmpty == true
                                        ? finance.userProfile!.name
                                        : 'Finsimer',
                                    style: GoogleFonts.outfit(color: nameColor, fontSize: 13, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    finance.userProfile?.profession.isNotEmpty == true
                                        ? finance.userProfile!.profession
                                        : (auth.currentUserEmail ?? 'guest@finsim.com'),
                                    style: GoogleFonts.inter(color: subColor, fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(color: divColor, height: 32),

                    // Navigation buttons
                    Expanded(
                      child: ListView.builder(
                        itemCount: _menuItems.length,
                        itemBuilder: (context, index) {
                          final item = _menuItems[index];
                          final bool isSelected = _selectedIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF00BFA5).withOpacity(0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0x3300BFA5) : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? item['activeIcon'] : item['icon'],
                                      color: isSelected ? const Color(0xFF00BFA5) : menuItemColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      item['title'],
                                      style: GoogleFonts.outfit(
                                        color: isSelected ? const Color(0xFF00BFA5) : menuItemColor,
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Log out button
                    Divider(color: divColor, height: 24),
                    GlassButton(
                      color: Colors.redAccent,
                      borderRadius: 12.0,
                      onPressed: () async {
                        finance.clear();
                        await auth.signOut();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('KELUAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Screen Area
            Expanded(
              child: Column(
                children: [
                  _buildDesktopTopBar(),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB-HEADERS & NAV BARS ---
  Widget _buildAppBarHeader() {
    final finance = Provider.of<FinanceController>(context);
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = themeCtrl.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 12.0, top: 12.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _menuItems[_selectedIndex]['title'],
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          Row(
            children: [
              // Theme toggle button
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: isDark ? Colors.amberAccent : const Color(0xFF546E7A),
                  size: 22,
                ),
                onPressed: () => themeCtrl.toggleTheme(),
                tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
              ),
              const SizedBox(width: 4),
              // Profile avatar
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF00BFA5).withOpacity(0.15),
                  backgroundImage: _getProfileImageProvider(finance.userProfile?.photoUrl ?? ''),
                  child: _getProfileImageProvider(finance.userProfile?.photoUrl ?? '') != null
                      ? null
                      : Icon(Icons.person_outline, color: isDark ? Colors.white70 : const Color(0xFF546E7A), size: 20),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDesktopTopBar() {
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = themeCtrl.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _menuItems[_selectedIndex]['title'],
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          Row(
            children: [
              // Theme toggle button
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: isDark ? Colors.amberAccent : const Color(0xFF546E7A),
                  size: 22,
                ),
                onPressed: () => themeCtrl.toggleTheme(),
                tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
              ),
              const SizedBox(width: 8),
              Icon(Icons.notifications_outlined, color: isDark ? Colors.white70 : const Color(0xFF546E7A)),
            ],
          ),
        ],
      ),
    );
  }
}

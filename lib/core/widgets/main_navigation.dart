import 'package:flutter/material.dart';
import 'package:phcl_accounts/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:phcl_accounts/features/settings/presentation/pages/settings_page.dart';
import 'package:phcl_accounts/features/transactions/presentation/pages/transactions_page.dart';

class MainNavigation extends StatefulWidget {
  final int? initialIndex;
  const MainNavigation({super.key, this.initialIndex});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
    // final PageController _pageController = PageController();

  final List<Widget> _screens = [
    DashboardPage(),
    TransactionsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
  }

  @override
  void dispose() {
    // _pageController.dispose();
    super.dispose();
  }

//     @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: PageView(
//           controller: _pageController,
//           physics: const NeverScrollableScrollPhysics(), // Disable swipe
//           children: _screens,
//           onPageChanged: (index) {
//             setState(() => _selectedIndex = index);
//           },
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           setState(() => _selectedIndex = index);
//           _pageController.jumpToPage(index);
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.receipt),
//             label: 'Transactions',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'deliveries/deliveries_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import '../providers/notifications_provider.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DeliveriesScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Deliveries',
          ),
          NavigationDestination(
            icon: Consumer<NotificationsProvider>(
              builder: (context, provider, child) {
                return Badge(
                  isLabelVisible: provider.hasUnread,
                  label: Text('${provider.unreadCount}'),
                  child: const Icon(Icons.notifications_outlined),
                );
              },
            ),
            selectedIcon: Consumer<NotificationsProvider>(
              builder: (context, provider, child) {
                return Badge(
                  isLabelVisible: provider.hasUnread,
                  label: Text('${provider.unreadCount}'),
                  child: const Icon(Icons.notifications),
                );
              },
            ),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

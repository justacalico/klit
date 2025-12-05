import 'package:flutter/cupertino.dart';
import 'home/home_page.dart';
import 'hot/hot_page.dart';
import 'popular/popular_page.dart';
import 'profile/profile_page.dart';
import 'settings/settings_page.dart';

/// Main tab navigation page
class MainTabPage extends StatelessWidget {
  const MainTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            activeIcon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.flame),
            activeIcon: Icon(CupertinoIcons.flame_fill),
            label: 'Hot',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.star),
            activeIcon: Icon(CupertinoIcons.star_fill),
            label: 'Popular',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            activeIcon: Icon(CupertinoIcons.person_fill),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            activeIcon: Icon(CupertinoIcons.settings_solid),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const HomePage();
          case 1:
            return const HotPage();
          case 2:
            return const PopularPage();
          case 3:
            return const ProfilePage();
          case 4:
            return const SettingsPage();
          default:
            return const HomePage();
        }
      },
    );
  }
}

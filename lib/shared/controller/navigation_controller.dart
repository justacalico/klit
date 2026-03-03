import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:klit/app/routes/app_routes.dart';

class NavItem {
  const NavItem(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

class NavigationController extends GetxController {
  NavigationController({required this.items, this.mobilePrimaryCount = 4});

  final List<NavItem> items;
  final int mobilePrimaryCount;

  final Rx<String> currentPath = '/'.obs;
  final RxBool sidebarCollapsed = false.obs;
  final Rx<int?> profileViewUserId = Rx<int?>(null);
  final Rx<String?> profileViewUsername = Rx<String?>(null);
  final Rx<String?> searchInitialQuery = Rx<String?>(null);
  bool _requestSearchFocus = false;

  void toggleSidebar() => sidebarCollapsed.toggle();

  bool takeRequestSearchFocus() {
    final v = _requestSearchFocus;
    _requestSearchFocus = false;
    return v;
  }

  int get currentIndex {
    final i = items.indexWhere((e) => e.path == currentPath.value);
    return i >= 0 ? i : 0;
  }

  void goTo(int index) {
    if (index < 0 || index >= items.length) return;
    final path = items[index].path;
    if (path == '/profile') {
      profileViewUserId.value = null;
      profileViewUsername.value = null;
    }
    if (path == '/') searchInitialQuery.value = null;
    if (path == '/search') _requestSearchFocus = true;
    currentPath.value = path;

    final currentRoute = Get.currentRoute;
    if (currentRoute != AppRoutes.home) {
      Get.offAllNamed(
        AppRoutes.home,
        arguments: {'path': path},
      );
    }
  }
}
